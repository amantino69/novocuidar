import { Injectable, Inject, PLATFORM_ID, NgZone } from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import { Subject, BehaviorSubject } from 'rxjs';

// Interfaces para dispositivos médicos Bluetooth
export interface BluetoothDevice {
  id: string;
  name: string;
  type: DeviceType;
  connected: boolean;
  batteryLevel?: number;
  lastReading?: Date;
}

export type DeviceType = 'oximeter' | 'thermometer' | 'scale' | 'blood_pressure' | 'stethoscope';

export interface VitalReading {
  deviceId: string;
  deviceType: DeviceType;
  timestamp: Date;
  values: VitalValues;
}

export interface VitalValues {
  // Oxímetro
  spo2?: number;           // % saturação
  pulseRate?: number;      // bpm
  perfusionIndex?: number; // %

  // Termômetro
  temperature?: number;    // °C

  // Balança
  weight?: number;         // kg
  bmi?: number;           // calculado

  // Pressão arterial
  systolic?: number;       // mmHg
  diastolic?: number;      // mmHg
  heartRate?: number;      // bpm
}

// UUIDs padrão para dispositivos médicos (GATT Health profiles)
const GATT_SERVICES = {
  // Health Thermometer Service
  HEALTH_THERMOMETER: '00001809-0000-1000-8000-00805f9b34fb',
  THERMOMETER_MEASUREMENT: '00002a1c-0000-1000-8000-00805f9b34fb',

  // Heart Rate Service
  HEART_RATE: '0000180d-0000-1000-8000-00805f9b34fb',
  HEART_RATE_MEASUREMENT: '00002a37-0000-1000-8000-00805f9b34fb',

  // Blood Pressure Service
  BLOOD_PRESSURE: '00001810-0000-1000-8000-00805f9b34fb',
  BLOOD_PRESSURE_MEASUREMENT: '00002a35-0000-1000-8000-00805f9b34fb',
  INTERMEDIATE_CUFF_PRESSURE: '00002a36-0000-1000-8000-00805f9b34fb',
  RECORD_ACCESS_CONTROL_POINT: '00002a52-0000-1000-8000-00805f9b34fb',

  // Weight Scale Service (genérico)
  WEIGHT_SCALE: '0000181d-0000-1000-8000-00805f9b34fb',
  WEIGHT_MEASUREMENT: '00002a9d-0000-1000-8000-00805f9b34fb',

  // Body Composition Service (Xiaomi MIBFS)
  BODY_COMPOSITION: '0000181b-0000-1000-8000-00805f9b34fb',
  BODY_COMPOSITION_MEASUREMENT: '00002a9c-0000-1000-8000-00805f9b34fb',

  // Pulse Oximeter Service
  PULSE_OXIMETER: '00001822-0000-1000-8000-00805f9b34fb',
  PLX_SPOT_CHECK: '00002a5e-0000-1000-8000-00805f9b34fb',
  PLX_CONTINUOUS: '00002a5f-0000-1000-8000-00805f9b34fb',

  // Battery Service
  BATTERY: '0000180f-0000-1000-8000-00805f9b34fb',
  BATTERY_LEVEL: '00002a19-0000-1000-8000-00805f9b34fb',

  // Device Information
  DEVICE_INFO: '0000180a-0000-1000-8000-00805f9b34fb',

  // Eko/Littmann CORE Stethoscope (UUIDs proprietários)
  // Baseado em engenharia reversa - podem precisar de ajuste
  EKO_SERVICE: '0000ec00-0000-1000-8000-00805f9b34fb',           // Serviço principal Eko
  EKO_AUDIO_CHAR: '0000ec01-0000-1000-8000-00805f9b34fb',        // Característica de áudio
  EKO_CONTROL_CHAR: '0000ec02-0000-1000-8000-00805f9b34fb',      // Característica de controle
};

@Injectable({
  providedIn: 'root'
})
export class BluetoothDevicesService {
  private isBrowser: boolean;
  private devices = new Map<string, BluetoothDevice>();
  private gattServers = new Map<string, BluetoothRemoteGATTServer>();
  // Guarda referência aos dispositivos Web Bluetooth originais para reconexão
  private webBluetoothDevices = new Map<string, any>();
  // Mapeia tipo -> deviceId para encontrar dispositivo por tipo
  private deviceByType = new Map<DeviceType, string>();

  // Estado reativo
  private _devices$ = new BehaviorSubject<BluetoothDevice[]>([]);
  public devices$ = this._devices$.asObservable();

  private _readings$ = new Subject<VitalReading>();
  public readings$ = this._readings$.asObservable();

  private _connectionStatus$ = new BehaviorSubject<{ deviceId: string; status: 'connecting' | 'connected' | 'disconnected' | 'error'; message?: string } | null>(null);
  public connectionStatus$ = this._connectionStatus$.asObservable();

  // DEBUG: Logs para exibição visual (Android sem F12)
  private _debugLog$ = new Subject<{ msg: string; type: 'info' | 'success' | 'warning' | 'error' | 'data' }>();
  public debugLog$ = this._debugLog$.asObservable();

  private log(msg: string, type: 'info' | 'success' | 'warning' | 'error' | 'data' = 'info'): void {
    console.log(`[BLE] ${msg}`);
    this._debugLog$.next({ msg, type });
  }

  constructor(
    @Inject(PLATFORM_ID) private platformId: Object,
    private ngZone: NgZone
  ) {
    this.isBrowser = isPlatformBrowser(platformId);
  }

  /**
   * Verifica se Web Bluetooth está disponível
   */
  isBluetoothAvailable(): boolean {
    if (!this.isBrowser) return false;
    return 'bluetooth' in navigator;
  }

  /**
   * Conecta a um oxímetro de pulso
   */
  async connectOximeter(): Promise<BluetoothDevice | null> {
    return this.connectDevice('oximeter', [
      GATT_SERVICES.PULSE_OXIMETER,
      GATT_SERVICES.HEART_RATE
    ]);
  }

  /**
   * Conecta a um termômetro
   */
  async connectThermometer(): Promise<BluetoothDevice | null> {
    return this.connectDevice('thermometer', [
      GATT_SERVICES.HEALTH_THERMOMETER
    ]);
  }

  /**
   * Conecta a uma balança (suporta MIBFS/Xiaomi e balanças genéricas)
   * Usa acceptAllDevices para mostrar TODOS os dispositivos BLE próximos
   */
  async connectScale(): Promise<BluetoothDevice | null> {
    return this.connectScaleAny();
  }

  /**
   * Conecta a qualquer balança BLE - mostra todos dispositivos para seleção manual
   * Resolve problema de balanças com nomes não-padrão no Android
   */
  async connectScaleAny(): Promise<BluetoothDevice | null> {
    if (!this.isBluetoothAvailable()) {
      this.log('Web Bluetooth não disponível', 'error');
      return null;
    }

    try {
      this.log('Buscando balança (todos dispositivos)...', 'info');

      // acceptAllDevices: true mostra TODOS os dispositivos BLE próximos
      const device = await (navigator as any).bluetooth.requestDevice({
        acceptAllDevices: true,
        optionalServices: [
          GATT_SERVICES.BODY_COMPOSITION,
          GATT_SERVICES.WEIGHT_SCALE,
          GATT_SERVICES.BATTERY,
          GATT_SERVICES.DEVICE_INFO,
          // UUIDs genéricos para balanças chinesas
          '0000fff0-0000-1000-8000-00805f9b34fb',
          '0000ffe0-0000-1000-8000-00805f9b34fb',
        ]
      });

      if (!device) {
        this.log('Nenhum dispositivo selecionado', 'warning');
        return null;
      }

      const deviceId = device.id;
      this._connectionStatus$.next({ deviceId, status: 'connecting' });

      this.log(`Conectando a ${device.name || deviceId}...`, 'info');
      const server = await device.gatt.connect();
      this.log('GATT Server conectado!', 'success');

      this.gattServers.set(deviceId, server);
      // Guarda device original para reconexão
      this.webBluetoothDevices.set(deviceId, device);
      this.deviceByType.set('scale', deviceId);

      const bleDevice: BluetoothDevice = {
        id: deviceId,
        name: device.name || 'Balança',
        type: 'scale',
        connected: true,
        batteryLevel: await this.readBatteryLevel(server)
      };

      this.devices.set(deviceId, bleDevice);
      this._devices$.next(Array.from(this.devices.values()));
      this._connectionStatus$.next({ deviceId, status: 'connected' });

      device.addEventListener('gattserverdisconnected', () => {
        this.ngZone.run(() => {
          this.handleDisconnection(deviceId);
        });
      });

      // Tenta iniciar leitura (pode falhar se balança não usar protocolo padrão)
      try {
        this.log('Tentando protocolo MIBFS...', 'info');
        await this.startMIBFSReadings(server, deviceId);
      } catch (e) {
        this.log('MIBFS falhou, tentando genérico...', 'warning');
        await this.startGenericScaleReadings(server, deviceId);
      }

      this.log(`${device.name || 'Balança'} conectada! Aguardando peso...`, 'success');
      return bleDevice;

    } catch (error: any) {
      this.log(`ERRO: ${error.message}`, 'error');
      this._connectionStatus$.next({
        deviceId: 'unknown',
        status: 'error',
        message: error.message
      });
      return null;
    }
  }

  /**
   * Conecta especificamente à balança OKOK ou Xiaomi MIBFS (filtros específicos)
   */
  async connectScaleMIBFS(): Promise<BluetoothDevice | null> {
    if (!this.isBluetoothAvailable()) {
      console.error('[BluetoothDevices] Web Bluetooth não disponível');
      return null;
    }

    try {
      console.log('[BluetoothDevices] Buscando balança...');

      // Busca por nome (OKOK, MIBFS, MI Scale, etc) ou por serviços padrão
      const device = await (navigator as any).bluetooth.requestDevice({
        filters: [
          { namePrefix: 'OKOK' },          // Balança OKOK
          { namePrefix: 'Scale' },          // Balança genérica
          { namePrefix: 'MI' },             // Xiaomi
          { namePrefix: 'MIBFS' },          // Xiaomi Body Composition
          { services: [GATT_SERVICES.WEIGHT_SCALE] },
          { services: [GATT_SERVICES.BODY_COMPOSITION] }
        ],
        optionalServices: [
          GATT_SERVICES.BODY_COMPOSITION,
          GATT_SERVICES.WEIGHT_SCALE,
          GATT_SERVICES.BATTERY,
          GATT_SERVICES.DEVICE_INFO
        ]
      });

      if (!device) {
        console.log('[BluetoothDevices] Nenhum dispositivo selecionado');
        return null;
      }

      const deviceId = device.id;
      this._connectionStatus$.next({ deviceId, status: 'connecting' });

      console.log(`[BluetoothDevices] Conectando a ${device.name}...`);
      const server = await device.gatt.connect();

      this.gattServers.set(deviceId, server);
      // Guarda device original para reconexão
      this.webBluetoothDevices.set(deviceId, device);
      this.deviceByType.set('scale', deviceId);

      const bleDevice: BluetoothDevice = {
        id: deviceId,
        name: device.name || 'Balança MIBFS',
        type: 'scale',
        connected: true,
        batteryLevel: await this.readBatteryLevel(server)
      };

      this.devices.set(deviceId, bleDevice);
      this._devices$.next(Array.from(this.devices.values()));
      this._connectionStatus$.next({ deviceId, status: 'connected' });

      device.addEventListener('gattserverdisconnected', () => {
        this.ngZone.run(() => {
          this.handleDisconnection(deviceId);
        });
      });

      // Inicia leitura específica para MIBFS
      await this.startMIBFSReadings(server, deviceId);

      console.log(`[BluetoothDevices] ${device.name} conectado com sucesso!`);
      return bleDevice;

    } catch (error: any) {
      console.error('[BluetoothDevices] Erro ao conectar MIBFS:', error);
      this._connectionStatus$.next({
        deviceId: 'unknown',
        status: 'error',
        message: error.message
      });
      return null;
    }
  }

  /**
   * Conecta a um monitor de pressão
   */
  /**
   * Conecta ao monitor de pressão Omron HEM-7156T (ou similar)
   * Usa filtro por nome pois o Omron não anuncia serviço GATT padrão
   */
  async connectBloodPressure(): Promise<BluetoothDevice | null> {
    if (!this.isBluetoothAvailable()) {
      console.error('[BluetoothDevices] Web Bluetooth não disponível');
      return null;
    }

    try {
      console.log('[BluetoothDevices] Buscando monitor de pressão...');

      // IMPORTANTE: Omron não anuncia serviço padrão, buscar por nome ou aceitar qualquer dispositivo
      const device = await (navigator as any).bluetooth.requestDevice({
        filters: [
          { namePrefix: 'BLESmart' },    // Omron usa esse prefixo
          { namePrefix: 'Omron' },
          { namePrefix: 'HEM' },
          { services: [GATT_SERVICES.BLOOD_PRESSURE] }  // Fallback para outros monitores
        ],
        optionalServices: [
          GATT_SERVICES.BLOOD_PRESSURE,
          GATT_SERVICES.BATTERY,
          GATT_SERVICES.DEVICE_INFO
        ]
      });

      if (!device) {
        console.log('[BluetoothDevices] Nenhum dispositivo selecionado');
        return null;
      }

      const deviceId = device.id;
      this._connectionStatus$.next({ deviceId, status: 'connecting' });

      console.log(`[BluetoothDevices] Conectando a ${device.name}...`);
      const server = await device.gatt.connect();

      this.gattServers.set(deviceId, server);
      // Guarda device original para reconexão
      this.webBluetoothDevices.set(deviceId, device);
      this.deviceByType.set('blood_pressure', deviceId);

      const bleDevice: BluetoothDevice = {
        id: deviceId,
        name: device.name || 'Monitor de Pressão',
        type: 'blood_pressure',
        connected: true,
        batteryLevel: await this.readBatteryLevel(server)
      };

      this.devices.set(deviceId, bleDevice);
      this._devices$.next(Array.from(this.devices.values()));
      this._connectionStatus$.next({ deviceId, status: 'connected' });

      device.addEventListener('gattserverdisconnected', () => {
        this.ngZone.run(() => {
          this.handleDisconnection(deviceId);
        });
      });

      // Inicia leituras
      await this.startBloodPressureReadings(server, deviceId);

      console.log(`[BluetoothDevices] ${device.name} conectado com sucesso!`);
      return bleDevice;

    } catch (error: any) {
      console.error('[BluetoothDevices] Erro ao conectar monitor de pressão:', error);
      this._connectionStatus$.next({
        deviceId: 'unknown',
        status: 'error',
        message: error.message
      });
      return null;
    }
  }

  /**
   * Conecta ao estetoscópio Littmann CORE / Eko CORE via Web Bluetooth
   * Retorna informações sobre serviços disponíveis para debug
   */
  async connectStethoscope(): Promise<{ device: BluetoothDevice | null; services: string[] }> {
    if (!this.isBluetoothAvailable()) {
      console.error('[BluetoothDevices] Web Bluetooth não disponível');
      return { device: null, services: [] };
    }

    try {
      console.log('[BluetoothDevices] Buscando Littmann CORE / Eko...');

      // Busca por nome - Eko/Littmann CORE pode aparecer com diferentes nomes
      const device = await (navigator as any).bluetooth.requestDevice({
        filters: [
          { namePrefix: 'CORE' },
          { namePrefix: 'Littmann' },
          { namePrefix: 'Eko' },
          { namePrefix: 'EKO' }
        ],
        // Aceita todos os serviços para descoberta
        optionalServices: [
          GATT_SERVICES.EKO_SERVICE,
          GATT_SERVICES.BATTERY,
          GATT_SERVICES.DEVICE_INFO,
          GATT_SERVICES.HEART_RATE,
          // UUIDs genéricos para descoberta
          '00001800-0000-1000-8000-00805f9b34fb', // Generic Access
          '00001801-0000-1000-8000-00805f9b34fb', // Generic Attribute
        ]
      });

      if (!device) {
        console.log('[BluetoothDevices] Nenhum dispositivo selecionado');
        return { device: null, services: [] };
      }

      const deviceId = device.id;
      this._connectionStatus$.next({ deviceId, status: 'connecting' });

      console.log(`[BluetoothDevices] Conectando ao ${device.name}...`);
      const server = await device.gatt.connect();

      this.gattServers.set(deviceId, server);
      // Guarda device original para reconexão
      this.webBluetoothDevices.set(deviceId, device);
      this.deviceByType.set('stethoscope', deviceId);

      // Enumera todos os serviços disponíveis para descoberta
      console.log('[BluetoothDevices] Enumerando serviços do Littmann CORE...');
      const discoveredServices: string[] = [];

      try {
        const services = await server.getPrimaryServices();
        for (const service of services) {
          console.log(`[BluetoothDevices] Serviço encontrado: ${service.uuid}`);
          discoveredServices.push(service.uuid);

          // Enumera características de cada serviço
          try {
            const characteristics = await service.getCharacteristics();
            for (const char of characteristics) {
              console.log(`[BluetoothDevices]   └─ Característica: ${char.uuid}, props: ${JSON.stringify(char.properties)}`);

              // Se a característica suporta notify, tenta iniciar para ver se é áudio
              if (char.properties.notify) {
                console.log(`[BluetoothDevices]      ↳ Suporta NOTIFY - pode ser áudio!`);
              }
            }
          } catch (e) {
            console.log(`[BluetoothDevices]   └─ Erro ao enumerar características: ${e}`);
          }
        }
      } catch (e) {
        console.error('[BluetoothDevices] Erro ao enumerar serviços:', e);
      }

      const bleDevice: BluetoothDevice = {
        id: deviceId,
        name: device.name || 'Littmann CORE',
        type: 'stethoscope',
        connected: true,
        batteryLevel: await this.readBatteryLevel(server)
      };

      this.devices.set(deviceId, bleDevice);
      this._devices$.next(Array.from(this.devices.values()));
      this._connectionStatus$.next({ deviceId, status: 'connected' });

      device.addEventListener('gattserverdisconnected', () => {
        this.ngZone.run(() => {
          this.handleDisconnection(deviceId);
        });
      });

      console.log(`[BluetoothDevices] ${device.name} conectado! Serviços: ${discoveredServices.join(', ')}`);
      return { device: bleDevice, services: discoveredServices };

    } catch (error: any) {
      console.error('[BluetoothDevices] Erro ao conectar Littmann CORE:', error);
      this._connectionStatus$.next({
        deviceId: 'unknown',
        status: 'error',
        message: error.message
      });
      return { device: null, services: [] };
    }
  }

  /**
   * Inicia streaming de áudio do estetoscópio Eko/Littmann CORE
   * @param serviceUuid UUID do serviço de áudio (descoberto via connectStethoscope)
   * @param characteristicUuid UUID da característica de áudio
   * @param onAudioData Callback chamado com chunks de áudio PCM
   */
  async startStethoscopeAudio(
    serviceUuid: string,
    characteristicUuid: string,
    onAudioData: (data: Uint8Array) => void
  ): Promise<boolean> {
    const server = Array.from(this.gattServers.values())[0];
    if (!server) {
      console.error('[BluetoothDevices] Nenhum servidor GATT conectado');
      return false;
    }

    try {
      const service = await server.getPrimaryService(serviceUuid);
      const char = await service.getCharacteristic(characteristicUuid);

      await char.startNotifications();
      console.log('[BluetoothDevices] Notificações de áudio iniciadas!');

      char.addEventListener('characteristicvaluechanged', (event: Event) => {
        const target = event.target as unknown as BluetoothRemoteGATTCharacteristic;
        const value = target.value!;
        const data = new Uint8Array(value.buffer);

        this.ngZone.run(() => {
          onAudioData(data);
        });
      });

      return true;
    } catch (error) {
      console.error('[BluetoothDevices] Erro ao iniciar áudio:', error);
      return false;
    }
  }

  /**
   * Conecta a um dispositivo genérico
   */
  private async connectDevice(type: DeviceType, services: string[]): Promise<BluetoothDevice | null> {
    if (!this.isBluetoothAvailable()) {
      console.error('[BluetoothDevices] Web Bluetooth não disponível');
      return null;
    }

    try {
      console.log(`[BluetoothDevices] Buscando ${type}...`);

      // Solicita dispositivo ao usuário
      const device = await (navigator as any).bluetooth.requestDevice({
        filters: services.map(service => ({ services: [service] })),
        optionalServices: [GATT_SERVICES.BATTERY, GATT_SERVICES.DEVICE_INFO]
      });

      if (!device) {
        console.log('[BluetoothDevices] Nenhum dispositivo selecionado');
        return null;
      }

      const deviceId = device.id;
      this._connectionStatus$.next({ deviceId, status: 'connecting' });

      // Conecta ao GATT server
      console.log(`[BluetoothDevices] Conectando a ${device.name}...`);
      const server = await device.gatt.connect();

      this.gattServers.set(deviceId, server);
      // Guarda device original para reconexão
      this.webBluetoothDevices.set(deviceId, device);
      this.deviceByType.set(type, deviceId);

      // Cria o registro do dispositivo
      const bleDevice: BluetoothDevice = {
        id: deviceId,
        name: device.name || `Dispositivo ${type}`,
        type,
        connected: true,
        batteryLevel: await this.readBatteryLevel(server)
      };

      this.devices.set(deviceId, bleDevice);
      this._devices$.next(Array.from(this.devices.values()));
      this._connectionStatus$.next({ deviceId, status: 'connected' });

      // Configura listeners de desconexão
      device.addEventListener('gattserverdisconnected', () => {
        this.ngZone.run(() => {
          this.handleDisconnection(deviceId);
        });
      });

      // Inicia leitura de dados
      await this.startReadings(server, type, deviceId);

      console.log(`[BluetoothDevices] ${device.name} conectado com sucesso!`);
      return bleDevice;

    } catch (error: any) {
      console.error('[BluetoothDevices] Erro ao conectar:', error);
      this._connectionStatus$.next({
        deviceId: 'unknown',
        status: 'error',
        message: error.message
      });
      return null;
    }
  }

  /**
   * Lê nível da bateria
   */
  private async readBatteryLevel(server: BluetoothRemoteGATTServer): Promise<number | undefined> {
    try {
      const batteryService = await server.getPrimaryService(GATT_SERVICES.BATTERY);
      const batteryChar = await batteryService.getCharacteristic(GATT_SERVICES.BATTERY_LEVEL);
      const value = await batteryChar.readValue();
      return value.getUint8(0);
    } catch {
      return undefined;
    }
  }

  /**
   * Inicia leituras contínuas do dispositivo
   */
  private async startReadings(server: BluetoothRemoteGATTServer, type: DeviceType, deviceId: string): Promise<void> {
    try {
      switch (type) {
        case 'oximeter':
          await this.startOximeterReadings(server, deviceId);
          break;
        case 'thermometer':
          await this.startThermometerReadings(server, deviceId);
          break;
        case 'scale':
          await this.startScaleReadings(server, deviceId);
          break;
        case 'blood_pressure':
          await this.startBloodPressureReadings(server, deviceId);
          break;
      }
    } catch (error) {
      console.error(`[BluetoothDevices] Erro ao iniciar leituras de ${type}:`, error);
    }
  }

  /**
   * Leituras do oxímetro
   */
  private async startOximeterReadings(server: BluetoothRemoteGATTServer, deviceId: string): Promise<void> {
    try {
      // Tenta serviço de oxímetro
      const service = await server.getPrimaryService(GATT_SERVICES.PULSE_OXIMETER);
      const char = await service.getCharacteristic(GATT_SERVICES.PLX_CONTINUOUS);

      await char.startNotifications();
      char.addEventListener('characteristicvaluechanged', (event: Event) => {
        const target = event.target as unknown as BluetoothRemoteGATTCharacteristic;
        const value = target.value!;

        this.ngZone.run(() => {
          // Formato padrão PLX: SpO2 (1 byte), Pulse Rate (2 bytes)
          const spo2 = value.getUint8(1);
          const pulseRate = value.getUint16(3, true);

          this._readings$.next({
            deviceId,
            deviceType: 'oximeter',
            timestamp: new Date(),
            values: { spo2, pulseRate }
          });

          this.updateDeviceLastReading(deviceId);
        });
      });
    } catch (error) {
      // Fallback: tenta Heart Rate Service
      try {
        const hrService = await server.getPrimaryService(GATT_SERVICES.HEART_RATE);
        const hrChar = await hrService.getCharacteristic(GATT_SERVICES.HEART_RATE_MEASUREMENT);

        await hrChar.startNotifications();
        hrChar.addEventListener('characteristicvaluechanged', (event: Event) => {
          const target = event.target as unknown as BluetoothRemoteGATTCharacteristic;
          const value = target.value!;

          this.ngZone.run(() => {
            const flags = value.getUint8(0);
            const is16Bit = (flags & 0x01) !== 0;
            const heartRate = is16Bit ? value.getUint16(1, true) : value.getUint8(1);

            this._readings$.next({
              deviceId,
              deviceType: 'oximeter',
              timestamp: new Date(),
              values: { pulseRate: heartRate }
            });

            this.updateDeviceLastReading(deviceId);
          });
        });
      } catch (e) {
        console.error('[BluetoothDevices] Erro no fallback Heart Rate:', e);
      }
    }
  }

  /**
   * Leituras do termômetro
   */
  private async startThermometerReadings(server: BluetoothRemoteGATTServer, deviceId: string): Promise<void> {
    const service = await server.getPrimaryService(GATT_SERVICES.HEALTH_THERMOMETER);
    const char = await service.getCharacteristic(GATT_SERVICES.THERMOMETER_MEASUREMENT);

    await char.startNotifications();
    char.addEventListener('characteristicvaluechanged', (event: Event) => {
      const target = event.target as unknown as BluetoothRemoteGATTCharacteristic;
      const value = target.value!;

      this.ngZone.run(() => {
        // IEEE 11073 float format
        const mantissa = value.getUint8(1) | (value.getUint8(2) << 8) | (value.getUint8(3) << 16);
        const exponent = value.getInt8(4);
        const temperature = mantissa * Math.pow(10, exponent);

        this._readings$.next({
          deviceId,
          deviceType: 'thermometer',
          timestamp: new Date(),
          values: { temperature: parseFloat(temperature.toFixed(1)) }
        });

        this.updateDeviceLastReading(deviceId);
      });
    });
  }

  /**
   * Leituras da balança
   */
  private async startScaleReadings(server: BluetoothRemoteGATTServer, deviceId: string): Promise<void> {
    const service = await server.getPrimaryService(GATT_SERVICES.WEIGHT_SCALE);
    const char = await service.getCharacteristic(GATT_SERVICES.WEIGHT_MEASUREMENT);

    await char.startNotifications();
    char.addEventListener('characteristicvaluechanged', (event: Event) => {
      const target = event.target as unknown as BluetoothRemoteGATTCharacteristic;
      const value = target.value!;

      this.ngZone.run(() => {
        const flags = value.getUint8(0);
        const isImperial = (flags & 0x01) !== 0;
        let weight = value.getUint16(1, true);

        // Converte para kg se necessário
        if (isImperial) {
          weight = weight * 0.453592; // lbs to kg
        } else {
          weight = weight / 200; // Resolução padrão: 0.005 kg
        }

        this._readings$.next({
          deviceId,
          deviceType: 'scale',
          timestamp: new Date(),
          values: { weight: parseFloat(weight.toFixed(1)) }
        });

        this.updateDeviceLastReading(deviceId);
      });
    });
  }

  /**
   * Leituras específicas da balança Xiaomi MIBFS (Body Composition)
   * A MIBFS usa o serviço Body Composition (181B) ao invés do Weight Scale (181D)
   */
  private async startMIBFSReadings(server: BluetoothRemoteGATTServer, deviceId: string): Promise<void> {
    try {
      console.log('[BluetoothDevices] Iniciando leituras MIBFS...');

      const service = await server.getPrimaryService(GATT_SERVICES.BODY_COMPOSITION);
      const char = await service.getCharacteristic(GATT_SERVICES.BODY_COMPOSITION_MEASUREMENT);

      await char.startNotifications();
      console.log('[BluetoothDevices] Notificações MIBFS ativadas');

      let primeiraLeituraIgnorada = false;
      const inicioConexao = Date.now();

      char.addEventListener('characteristicvaluechanged', (event: Event) => {
        const target = event.target as unknown as BluetoothRemoteGATTCharacteristic;
        const value = target.value!;

        this.ngZone.run(() => {
          const bytes = Array.from(new Uint8Array(value.buffer));
          console.log('[BluetoothDevices] MIBFS bytes recebidos:', bytes.join(', '));

          // Formato MIBFS: byte 1 = flags, bytes 2-3 = peso (little endian), bytes 4-5 = impedância
          const flags = value.getUint8(1);
          const estabilizado = (flags & 0x20) !== 0;
          const rawPeso = value.getUint16(2, true);
          const peso = rawPeso / 200; // Resolução: 0.005 kg

          let impedancia = 0;
          if (value.byteLength >= 6) {
            impedancia = value.getUint16(4, true);
          }

          console.log(`[BluetoothDevices] MIBFS - Peso: ${peso.toFixed(2)}kg, Impedância: ${impedancia}, Estab: ${estabilizado}`);

          // Ignora primeira leitura (cache da ROM)
          if (!primeiraLeituraIgnorada) {
            console.log('[BluetoothDevices] MIBFS - Ignorando cache ROM');
            primeiraLeituraIgnorada = true;
            return;
          }

          // Ignora leituras nos primeiros 5 segundos (lixo inicial)
          const tempoDecorrido = Date.now() - inicioConexao;
          if (tempoDecorrido < 5000) {
            console.log('[BluetoothDevices] MIBFS - Ignorando leitura inicial');
            return;
          }

          // Só emite se peso válido (> 2kg) e estabilizado ou impedância detectada
          if (peso > 2 && (estabilizado || impedancia > 100)) {
            console.log(`[BluetoothDevices] MIBFS - CAPTURADO: ${peso.toFixed(1)} kg`);

            this._readings$.next({
              deviceId,
              deviceType: 'scale',
              timestamp: new Date(),
              values: { weight: parseFloat(peso.toFixed(1)) }
            });

            this.updateDeviceLastReading(deviceId);
          }
        });
      });

      console.log('[BluetoothDevices] MIBFS - Listener registrado. SUBA NA BALANÇA!');

    } catch (error) {
      this.log('Erro leituras MIBFS - tentando fallback...', 'warning');
      await this.startScaleReadings(server, deviceId);
    }
  }

  /**
   * Leituras genéricas para balanças que não usam protocolo MIBFS
   * Tenta descobrir serviços disponíveis e ler peso
   */
  private async startGenericScaleReadings(server: BluetoothRemoteGATTServer, deviceId: string): Promise<void> {
    try {
      this.log('Iniciando leituras genéricas...', 'info');

      // Enumera todos os serviços disponíveis
      const services = await server.getPrimaryServices();
      this.log(`Serviços: ${services.length} encontrados`, 'info');

      for (const service of services) {
        const shortUuid = service.uuid.substring(0, 8);
        this.log(`Serviço: ${shortUuid}...`, 'info');

        try {
          const characteristics = await service.getCharacteristics();

          for (const char of characteristics) {
            const shortCharUuid = char.uuid.substring(0, 8);

            // Se suporta notificações, ativa
            if (char.properties.notify) {
              try {
                await char.startNotifications();
                this.log(`Notify ON: ${shortCharUuid}`, 'success');

                char.addEventListener('characteristicvaluechanged', (event: Event) => {
                  const target = event.target as unknown as BluetoothRemoteGATTCharacteristic;
                  const value = target.value!;

                  this.ngZone.run(() => {
                    const bytes = Array.from(new Uint8Array(value.buffer));
                    this.log(`Dados: [${bytes.slice(0,8).join(',')}${bytes.length > 8 ? '...' : ''}]`, 'info');

                    // Tenta interpretar como peso (diversos formatos comuns)
                    const peso = this.tryParseWeight(value);
                    if (peso !== null && peso > 2 && peso < 300) {
                      this.log(`>>> PESO: ${peso.toFixed(1)} kg`, 'data');

                      this._readings$.next({
                        deviceId,
                        deviceType: 'scale',
                        timestamp: new Date(),
                        values: { weight: parseFloat(peso.toFixed(1)) }
                      });

                      this.updateDeviceLastReading(deviceId);
                    }
                  });
                });
              } catch (e) {
                console.log(`[BluetoothDevices]   -> Falha ao ativar notificações: ${e}`);
              }
            }
          }
        } catch (e) {
          console.log(`[BluetoothDevices] Erro ao enumerar características de ${service.uuid}:`, e);
        }
      }

      console.log('[BluetoothDevices] Listeners genéricos registrados. SUBA NA BALANÇA!');

    } catch (error) {
      console.error('[BluetoothDevices] Erro ao iniciar leituras genéricas:', error);
      throw error;
    }
  }

  /**
   * Tenta interpretar um DataView como valor de peso
   * Suporta diversos formatos comuns de balanças chinesas
   */
  private tryParseWeight(value: DataView): number | null {
    const len = value.byteLength;

    // Formato 1: MIBFS/Xiaomi - peso em bytes 2-3 (little endian, /200)
    if (len >= 4) {
      const peso1 = value.getUint16(2, true) / 200;
      if (peso1 > 2 && peso1 < 300) {
        console.log(`[BluetoothDevices] Formato MIBFS detectado: ${peso1.toFixed(1)} kg`);
        return peso1;
      }
    }

    // Formato 2: Weight Scale Service - peso em bytes 1-2 (little endian, /200)
    if (len >= 3) {
      const peso2 = value.getUint16(1, true) / 200;
      if (peso2 > 2 && peso2 < 300) {
        console.log(`[BluetoothDevices] Formato WSS detectado: ${peso2.toFixed(1)} kg`);
        return peso2;
      }
    }

    // Formato 3: Balanças simples - peso em bytes 0-1 (little endian, /100)
    if (len >= 2) {
      const peso3 = value.getUint16(0, true) / 100;
      if (peso3 > 2 && peso3 < 300) {
        console.log(`[BluetoothDevices] Formato simples /100 detectado: ${peso3.toFixed(1)} kg`);
        return peso3;
      }
    }

    // Formato 4: Balanças simples - peso em bytes 0-1 (little endian, /10)
    if (len >= 2) {
      const peso4 = value.getUint16(0, true) / 10;
      if (peso4 > 2 && peso4 < 300) {
        console.log(`[BluetoothDevices] Formato simples /10 detectado: ${peso4.toFixed(1)} kg`);
        return peso4;
      }
    }

    return null;
  }

  /**
   * Decodifica valor SFLOAT (Short Float) do padrão IEEE 11073
   * SFLOAT: 16 bits = 4 bits expoente + 12 bits mantissa (com sinal)
   */
  private decodeSFLOAT(raw: number): number {
    // Valores especiais
    if (raw === 0x07FF) return NaN;  // NaN
    if (raw === 0x0800) return NaN;  // NRes
    if (raw === 0x07FE) return Infinity;  // +INFINITY
    if (raw === 0x0802) return -Infinity; // -INFINITY
    if (raw === 0x0801) return NaN;  // Reserved

    // Extrai mantissa (12 bits com sinal) e expoente (4 bits com sinal)
    let mantissa = raw & 0x0FFF;
    let exponent = (raw >> 12) & 0x0F;

    // Converte mantissa para signed (complemento de 2)
    if (mantissa >= 0x0800) {
      mantissa = mantissa - 0x1000;
    }

    // Converte expoente para signed (complemento de 2, 4 bits)
    if (exponent >= 0x08) {
      exponent = exponent - 0x10;
    }

    return mantissa * Math.pow(10, exponent);
  }

  /**
   * Handler para parsear dados de Blood Pressure Measurement
   * Compatível com Omron HEM-7156T e outros monitores Bluetooth padrão
   */
  private parseBloodPressureData(value: DataView, deviceId: string): void {
    // Log raw data para debug
    const bytes = Array.from(new Uint8Array(value.buffer));
    console.log('[BluetoothDevices] BP Raw:', bytes.map(b => '0x' + b.toString(16).padStart(2, '0')).join(' '));
    console.log('[BluetoothDevices] BP Bytes length:', value.byteLength);

    const flags = value.getUint8(0);
    const isKpa = (flags & 0x01) !== 0;
    const hasTimestamp = (flags & 0x02) !== 0;
    const hasPulseRate = (flags & 0x04) !== 0;
    const hasUserId = (flags & 0x08) !== 0;
    const hasMeasurementStatus = (flags & 0x10) !== 0;

    console.log(`[BluetoothDevices] BP Flags: kPa=${isKpa}, timestamp=${hasTimestamp}, pulse=${hasPulseRate}, userId=${hasUserId}, status=${hasMeasurementStatus}`);

    // Lê valores de pressão como SFLOAT (IEEE 11073)
    const rawSystolic = value.getUint16(1, true);
    const rawDiastolic = value.getUint16(3, true);
    const rawMap = value.getUint16(5, true);

    let systolic = this.decodeSFLOAT(rawSystolic);
    let diastolic = this.decodeSFLOAT(rawDiastolic);
    let map = this.decodeSFLOAT(rawMap);

    // Converte de kPa para mmHg se necessário
    if (isKpa) {
      systolic = Math.round(systolic * 7.5006);
      diastolic = Math.round(diastolic * 7.5006);
      map = Math.round(map * 7.5006);
    }

    console.log(`[BluetoothDevices] BP SFLOAT decoded: Sys=${systolic}, Dia=${diastolic}, MAP=${map}`);

    // Calcula offset para campos opcionais
    let offset = 7; // Após os 3 campos de pressão (cada um 2 bytes)

    // Timestamp: 7 bytes (Year:2, Month:1, Day:1, Hours:1, Minutes:1, Seconds:1)
    if (hasTimestamp) {
      offset += 7;
    }

    // Pulse rate (2 bytes SFLOAT)
    let heartRate: number | undefined;
    if (hasPulseRate && value.byteLength > offset + 1) {
      const rawPulse = value.getUint16(offset, true);
      heartRate = Math.round(this.decodeSFLOAT(rawPulse));
      offset += 2;
    }

    // Valida valores (sistólica deve ser > 50 e < 300 para ser válida)
    if (isNaN(systolic) || isNaN(diastolic) || systolic < 50 || systolic > 300 || diastolic < 30 || diastolic > 200) {
      console.warn(`[BluetoothDevices] BP valores inválidos ignorados: ${systolic}/${diastolic}`);
      return;
    }

    console.log(`[BluetoothDevices] BP Parsed: ${systolic}/${diastolic} mmHg, Pulse: ${heartRate ?? 'N/A'}`);

    this._readings$.next({
      deviceId,
      deviceType: 'blood_pressure',
      timestamp: new Date(),
      values: {
        systolic: Math.round(systolic),
        diastolic: Math.round(diastolic),
        heartRate
      }
    });

    this.updateDeviceLastReading(deviceId);
  }

  /**
   * Leituras do monitor de pressão (compatível com OMRON HEM-7156T e outros)
   * 
   * Formato Blood Pressure Measurement (0x2a35):
   * - Byte 0: Flags
   *   - Bit 0: Unidade (0 = mmHg, 1 = kPa)
   *   - Bit 1: Timestamp presente
   *   - Bit 2: Pulse Rate presente
   *   - Bit 3: User ID presente
   *   - Bit 4: Measurement Status presente
   * - Bytes 1-2: Sistólica (SFLOAT)
   * - Bytes 3-4: Diastólica (SFLOAT)
   * - Bytes 5-6: MAP (SFLOAT)
   * - Bytes 7-13: Timestamp (se presente - 7 bytes)
   * - Bytes após timestamp: Pulse Rate (2 bytes, se presente)
   */
  private async startBloodPressureReadings(server: BluetoothRemoteGATTServer, deviceId: string): Promise<void> {
    try {
      const service = await server.getPrimaryService(GATT_SERVICES.BLOOD_PRESSURE);

      // 1. Configura listener para Blood Pressure Measurement (0x2a35)
      const bpChar = await service.getCharacteristic(GATT_SERVICES.BLOOD_PRESSURE_MEASUREMENT);
      console.log('[BluetoothDevices] Blood Pressure Measurement - Configurando listener...');

      await bpChar.startNotifications();
      bpChar.addEventListener('characteristicvaluechanged', (event: Event) => {
        const target = event.target as unknown as BluetoothRemoteGATTCharacteristic;
        const value = target.value!;
        this.ngZone.run(() => this.parseBloodPressureData(value, deviceId));
      });

      // 2. Tenta configurar Intermediate Cuff Pressure (0x2a36) - opcional
      try {
        const icpChar = await service.getCharacteristic(GATT_SERVICES.INTERMEDIATE_CUFF_PRESSURE);
        console.log('[BluetoothDevices] Intermediate Cuff Pressure disponível');
        await icpChar.startNotifications();
        icpChar.addEventListener('characteristicvaluechanged', (event: Event) => {
          console.log('[BluetoothDevices] Intermediate Cuff Pressure recebido (medição em andamento)');
        });
      } catch (e) {
        console.log('[BluetoothDevices] Intermediate Cuff Pressure não disponível');
      }

      // 3. Tenta usar Record Access Control Point (0x2a52) para solicitar dados armazenados
      try {
        const racpChar = await service.getCharacteristic(GATT_SERVICES.RECORD_ACCESS_CONTROL_POINT);
        console.log('[BluetoothDevices] RACP disponível - solicitando dados armazenados...');

        await racpChar.startNotifications();
        racpChar.addEventListener('characteristicvaluechanged', (event: Event) => {
          const target = event.target as unknown as BluetoothRemoteGATTCharacteristic;
          const value = target.value!;
          const opCode = value.getUint8(0);
          console.log('[BluetoothDevices] RACP Response:', opCode);
        });

        // Comando: Report All Stored Records (Op Code = 0x01, Operator = 0x01 = All)
        const reportAllCmd = new Uint8Array([0x01, 0x01]);
        await racpChar.writeValue(reportAllCmd);
        console.log('[BluetoothDevices] RACP - Comando enviado para recuperar dados armazenados');
      } catch (e) {
        console.log('[BluetoothDevices] RACP não disponível - aguardando nova medição');
      }

      console.log('[BluetoothDevices] Blood Pressure - INICIE A MEDIÇÃO NO APARELHO!');
      console.log('[BluetoothDevices] DICA OMRON: Após conectar, inicie a medição no aparelho. Os dados serão enviados ao final.');
    } catch (error) {
      console.error('[BluetoothDevices] Serviço Blood Pressure não encontrado!');
      console.log('[BluetoothDevices] NOTA: Omron pode usar protocolo proprietário.');
      console.log('[BluetoothDevices] Conecte o dispositivo e faça uma medição - tentaremos capturar os dados.');

      // Para Omron: emite mensagem para o usuário fazer medição manual
      // Os dados podem não ser capturados automaticamente
      this._readings$.next({
        deviceId,
        deviceType: 'blood_pressure',
        timestamp: new Date(),
        values: {}  // Valores vazios, usuário precisa digitar
      });
    }
  }

  /**
   * Atualiza timestamp da última leitura
   */
  private updateDeviceLastReading(deviceId: string): void {
    const device = this.devices.get(deviceId);
    if (device) {
      device.lastReading = new Date();
      this.devices.set(deviceId, device);
      this._devices$.next(Array.from(this.devices.values()));
    }
  }

  /**
   * Trata desconexão
   */
  private handleDisconnection(deviceId: string): void {
    console.log(`[BluetoothDevices] Dispositivo ${deviceId} desconectado`);

    const device = this.devices.get(deviceId);
    if (device) {
      device.connected = false;
      this.devices.set(deviceId, device);
      this._devices$.next(Array.from(this.devices.values()));
    }

    this.gattServers.delete(deviceId);
    this._connectionStatus$.next({ deviceId, status: 'disconnected' });
  }

  /**
   * Desconecta um dispositivo
   */
  disconnect(deviceId: string): void {
    const server = this.gattServers.get(deviceId);
    if (server && server.connected) {
      server.disconnect();
    }
    this.handleDisconnection(deviceId);
  }

  /**
   * Desconecta todos os dispositivos
   */
  disconnectAll(): void {
    this.gattServers.forEach((server, deviceId) => {
      this.disconnect(deviceId);
    });
  }

  /**
   * Verifica se já temos um dispositivo conhecido de um tipo específico  
   * (pareado anteriormente nesta sessão)
   */
  hasKnownDevice(type: DeviceType): boolean {
    const deviceId = this.deviceByType.get(type);
    return !!deviceId && this.webBluetoothDevices.has(deviceId);
  }

  /**
   * Verifica se um dispositivo específico está conectado
   */
  isDeviceConnected(type: DeviceType): boolean {
    const deviceId = this.deviceByType.get(type);
    if (!deviceId) return false;
    const device = this.devices.get(deviceId);
    return device?.connected ?? false;
  }

  /**
   * Obtém nome do dispositivo conhecido de um tipo
   */
  getKnownDeviceName(type: DeviceType): string | null {
    const deviceId = this.deviceByType.get(type);
    if (!deviceId) return null;
    const device = this.devices.get(deviceId);
    return device?.name ?? null;
  }

  /**
   * Reconecta a um dispositivo já conhecido (sem picker do navegador)
   * Retorna true se reconectou com sucesso
   */
  async reconnect(type: DeviceType): Promise<BluetoothDevice | null> {
    const deviceId = this.deviceByType.get(type);
    if (!deviceId) {
      console.log(`[BluetoothDevices] Nenhum dispositivo ${type} conhecido`);
      return null;
    }

    const webDevice = this.webBluetoothDevices.get(deviceId);
    if (!webDevice) {
      console.log(`[BluetoothDevices] Dispositivo Web Bluetooth ${type} não encontrado na memória`);
      return null;
    }

    // Se já está conectado, retorna o dispositivo
    const existingServer = this.gattServers.get(deviceId);
    if (existingServer?.connected) {
      console.log(`[BluetoothDevices] ${type} já está conectado`);
      const existingDevice = this.devices.get(deviceId);
      return existingDevice ?? null;
    }

    try {
      this._connectionStatus$.next({ deviceId, status: 'connecting' });
      console.log(`[BluetoothDevices] Reconectando a ${webDevice.name}...`);

      // Reconecta sem abrir picker
      const server = await webDevice.gatt.connect();
      this.gattServers.set(deviceId, server);

      // Atualiza estado do dispositivo
      const bleDevice = this.devices.get(deviceId);
      if (bleDevice) {
        bleDevice.connected = true;
        bleDevice.batteryLevel = await this.readBatteryLevel(server);
        this.devices.set(deviceId, bleDevice);
        this._devices$.next(Array.from(this.devices.values()));
      }

      this._connectionStatus$.next({ deviceId, status: 'connected' });

      // Reinicia leituras
      await this.startReadings(server, type, deviceId);

      console.log(`[BluetoothDevices] ${webDevice.name} reconectado com sucesso!`);
      return bleDevice ?? null;

    } catch (error: any) {
      console.error(`[BluetoothDevices] Erro ao reconectar ${type}:`, error);
      this._connectionStatus$.next({
        deviceId,
        status: 'error',
        message: error.message
      });
      return null;
    }
  }

  /**
   * Conecta ou reconecta automaticamente a um tipo de dispositivo
   * Usa reconexão rápida se já conhece o dispositivo
   */
  async connectOrReconnect(type: DeviceType): Promise<BluetoothDevice | null> {
    // Se já conhece e está conectado, só retorna 
    if (this.isDeviceConnected(type)) {
      const deviceId = this.deviceByType.get(type);
      if (deviceId) {
        const device = this.devices.get(deviceId);
        console.log(`[BluetoothDevices] ${type} já conectado: ${device?.name}`);
        return device ?? null;
      }
    }

    // Se conhece mas desconectado, tenta reconectar 
    if (this.hasKnownDevice(type)) {
      console.log(`[BluetoothDevices] Tentando reconectar ${type}...`);
      const reconnected = await this.reconnect(type);
      if (reconnected) {
        return reconnected;
      }
      // Falhou reconexão, vai pedir novo pareamento
      console.log(`[BluetoothDevices] Reconexão falhou, solicitando novo pareamento`);
    }

    // Não conhece ou reconexão falhou - abre picker
    switch (type) {
      case 'scale':
        return this.connectScale();
      case 'blood_pressure':
        return this.connectBloodPressure();
      case 'stethoscope':
        const result = await this.connectStethoscope();
        return result.device;
      case 'thermometer':
        return this.connectThermometer();
      case 'oximeter':
        return this.connectOximeter();
      default:
        console.error(`[BluetoothDevices] Tipo desconhecido: ${type}`);
        return null;
    }
  }

  /**
   * Retorna dispositivos conectados
   */
  getConnectedDevices(): BluetoothDevice[] {
    return Array.from(this.devices.values()).filter(d => d.connected);
  }

  /**
   * Solicita leitura manual de um dispositivo
   */
  async requestReading(deviceId: string): Promise<void> {
    const device = this.devices.get(deviceId);
    const server = this.gattServers.get(deviceId);

    if (!device || !server || !server.connected) {
      console.warn('[BluetoothDevices] Dispositivo não conectado');
      return;
    }

    // Reinicia as leituras
    await this.startReadings(server, device.type, deviceId);
  }
}
