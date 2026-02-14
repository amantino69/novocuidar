#!/usr/bin/env python3
"""
Comparação de Frequência Cardíaca - Fonocardiograma vs Dispositivos Médicos
TeleCuidar POC - Fevereiro 2026

Compara a FC estimada do fonocardiograma com medições de:
- Omron HEM-7156T (pressão arterial)
- Oxímetro (SpO2)
- Balança (quando tem bioimpedância)
"""

import subprocess
import sys
import os
import json
from datetime import datetime

# Adiciona o diretório atual ao path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from analyze_phonocardiogram import analyze_phonocardiogram

VPS_HOST = "root@telecuidar.com.br"
PHONO_DIR_VPS = "/app/wwwroot/phonocardiograms"
LOCAL_TEMP = "C:\\telecuidar\\temp_phono"

def run_ssh(command):
    """Executa comando SSH e retorna output"""
    full_cmd = f'ssh {VPS_HOST} "{command}"'
    try:
        result = subprocess.run(full_cmd, shell=True, capture_output=True, text=True, timeout=30)
        return result.stdout.strip()
    except Exception as e:
        print(f"Erro SSH: {e}")
        return None

def list_recent_phonocardiograms(limit=10):
    """Lista os fonocardiogramas mais recentes na VPS"""
    cmd = f"docker exec telecuidar-backend ls -lt {PHONO_DIR_VPS} | head -{limit+1}"
    output = run_ssh(cmd)
    
    if not output:
        return []
    
    files = []
    for line in output.split('\n')[1:]:  # Pula o "total X"
        parts = line.split()
        if len(parts) >= 9 and parts[-1].endswith('.wav'):
            filename = parts[-1]
            # Extrai appointmentId do nome do arquivo
            # formato: phono_{appointmentId}_{timestamp}.wav
            parts_name = filename.replace('phono_', '').replace('.wav', '').split('_')
            if len(parts_name) >= 2:
                appointment_id = '_'.join(parts_name[:-1])  # Tudo menos o timestamp
                timestamp = parts_name[-1]
                files.append({
                    'filename': filename,
                    'appointment_id': appointment_id,
                    'timestamp': timestamp
                })
    return files

def download_phonocardiogram(filename):
    """Baixa fonocardiograma da VPS"""
    os.makedirs(LOCAL_TEMP, exist_ok=True)
    local_path = os.path.join(LOCAL_TEMP, filename)
    
    # Copia do container para /tmp na VPS
    run_ssh(f"docker cp telecuidar-backend:{PHONO_DIR_VPS}/{filename} /tmp/")
    
    # Baixa para local via SCP
    scp_cmd = f'scp {VPS_HOST}:/tmp/{filename} "{local_path}"'
    subprocess.run(scp_cmd, shell=True, capture_output=True)
    
    if os.path.exists(local_path):
        return local_path
    return None

def get_vital_signs_for_appointment(appointment_id):
    """Busca sinais vitais do banco para uma consulta específica"""
    query = f"""
    SELECT "Type", "Value", "Unit", "RecordedAt" 
    FROM "VitalSigns" 
    WHERE "AppointmentId" = '{appointment_id}' 
    ORDER BY "RecordedAt" DESC;
    """
    
    cmd = f"echo \\'{query}\\' | docker exec -i telecuidar-postgres psql -U telecuidar -d telecuidar -t -A -F ','"
    output = run_ssh(cmd)
    
    if not output:
        return []
    
    vitals = []
    for line in output.strip().split('\n'):
        if line and ',' in line:
            parts = line.split(',')
            if len(parts) >= 4:
                vitals.append({
                    'type': parts[0],
                    'value': parts[1],
                    'unit': parts[2],
                    'recorded_at': parts[3]
                })
    return vitals

def main():
    print("\n" + "="*70)
    print(" COMPARAÇÃO DE FREQUÊNCIA CARDÍACA - TeleCuidar")
    print("="*70)
    
    # 1. Lista fonocardiogramas recentes
    print("\n📋 Buscando fonocardiogramas recentes na VPS...")
    phonos = list_recent_phonocardiograms(10)
    
    if not phonos:
        print("❌ Nenhum fonocardiograma encontrado")
        return
    
    print(f"\n📁 Encontrados {len(phonos)} arquivos:")
    for i, p in enumerate(phonos):
        print(f"  [{i+1}] {p['filename']}")
    
    # 2. Seleciona arquivo
    print("\n" + "-"*70)
    choice = input("Digite o número do arquivo para analisar (Enter = mais recente): ").strip()
    
    if choice == '':
        selected = phonos[0]
    else:
        try:
            idx = int(choice) - 1
            selected = phonos[idx]
        except:
            print("❌ Opção inválida")
            return
    
    print(f"\n✅ Selecionado: {selected['filename']}")
    appointment_id = selected['appointment_id']
    print(f"   AppointmentId: {appointment_id}")
    
    # 3. Baixa o arquivo
    print("\n⬇️  Baixando arquivo...")
    local_path = download_phonocardiogram(selected['filename'])
    
    if not local_path:
        print("❌ Falha ao baixar arquivo")
        return
    
    print(f"   Salvo em: {local_path}")
    
    # 4. Analisa fonocardiograma
    print("\n" + "="*70)
    print(" ANÁLISE DO FONOCARDIOGRAMA")
    print("="*70)
    
    fc_ausculta = analyze_phonocardiogram(local_path)
    
    # 5. Busca sinais vitais da mesma consulta
    print("\n" + "="*70)
    print(" SINAIS VITAIS DA MESMA CONSULTA")
    print("="*70)
    
    print("\n📊 Buscando sinais vitais no banco de dados...")
    vitals = get_vital_signs_for_appointment(appointment_id)
    
    if not vitals:
        print("   ⚠️  Nenhum sinal vital encontrado para esta consulta")
    else:
        print(f"\n   Encontrados {len(vitals)} registros:\n")
        
        fc_devices = []
        
        for v in vitals:
            tipo = v['type']
            valor = v['value']
            unidade = v['unit']
            data = v['recorded_at'][:19] if len(v['recorded_at']) > 19 else v['recorded_at']
            
            # Identifica dispositivo pelo tipo
            if tipo == 'HeartRate':
                fc_devices.append(float(valor))
                print(f"   💓 FC (dispositivo): {valor} {unidade} - {data}")
            elif tipo == 'BloodPressureSystolic':
                print(f"   🩸 Pressão Sistólica: {valor} {unidade} - {data}")
            elif tipo == 'BloodPressureDiastolic':
                print(f"   🩸 Pressão Diastólica: {valor} {unidade} - {data}")
            elif tipo == 'SpO2':
                print(f"   🫁 SpO2: {valor} {unidade} - {data}")
            elif tipo == 'Weight':
                print(f"   ⚖️  Peso: {valor} {unidade} - {data}")
            elif tipo == 'Temperature':
                print(f"   🌡️  Temperatura: {valor} {unidade} - {data}")
            else:
                print(f"   📌 {tipo}: {valor} {unidade} - {data}")
    
    # 6. Comparação final
    print("\n" + "="*70)
    print(" COMPARAÇÃO DE FREQUÊNCIA CARDÍACA")
    print("="*70)
    
    print(f"\n   🩺 Fonocardiograma (ausculta): ", end="")
    if fc_ausculta:
        print(f"{fc_ausculta:.0f} BPM")
    else:
        print("Não foi possível estimar")
    
    if vitals:
        fc_devices = [float(v['value']) for v in vitals if v['type'] == 'HeartRate']
        if fc_devices:
            fc_medio = sum(fc_devices) / len(fc_devices)
            print(f"   💓 Dispositivos médicos: {fc_medio:.0f} BPM (média de {len(fc_devices)} medições)")
            
            if fc_ausculta and fc_medio:
                diff = abs(fc_ausculta - fc_medio)
                diff_pct = (diff / fc_medio) * 100
                print(f"\n   📏 Diferença: {diff:.0f} BPM ({diff_pct:.1f}%)")
                
                if diff <= 5:
                    print("   ✅ EXCELENTE: Medições muito próximas!")
                elif diff <= 10:
                    print("   ✅ BOM: Diferença aceitável para uso clínico")
                elif diff <= 20:
                    print("   ⚠️  MODERADO: Considere refazer a ausculta")
                else:
                    print("   ❌ ALTO: Provável problema na captura - refaça a ausculta")
        else:
            print("   ⚠️  Nenhuma medição de FC de outros dispositivos")
    
    print("\n" + "="*70 + "\n")
    
    # Limpa arquivo temporário
    try:
        os.remove(local_path)
    except:
        pass

if __name__ == "__main__":
    main()
