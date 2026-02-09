#!/usr/bin/env python3
"""
Script para preparar o banco de dados para demonstração do TeleCuidar
Data da apresentação: 12/02/2026

Usuários mantidos:
- adm_ca@telecuidar.com (admin)
- reg_go@telecuidar.com (regulador)
- enf_do@telecuidar.com (enfermeira/assistente)
- rec_ma@telecuidar.com (recepcionista)
- pac_dc@telecuidar.com (paciente - Daniel Carrara)
- med_aj@telecuidar.com (médico - Antônio Jorge - Psiquiatria)
- med_gt@telecuidar.com (médico - Geraldo Tadeu - Dermatologia)

Consultas:
- 4 consultas históricas (anteriores) com dados completos
- Consultas de 09/02 a 20/02/2026
"""

import psycopg2
import json
import uuid
from datetime import datetime, timedelta, time
import random

# Configuração do banco
DB_CONFIG = {
    "host": "localhost",
    "port": 5432,
    "database": "telecuidar",
    "user": "postgres",
    "password": "postgres"
}

# Emails dos usuários a manter
USERS_TO_KEEP = [
    "adm_ca@telecuidar.com",
    "reg_go@telecuidar.com",
    "enf_do@telecuidar.com",
    "pac_dc@telecuidar.com",
    "med_aj@telecuidar.com",
    "med_gt@telecuidar.com",
    "rec_ma@telecuidar.com"  # Recepcionista
]

def get_connection():
    """Conecta ao PostgreSQL"""
    return psycopg2.connect(**DB_CONFIG)

def get_users_ids(conn):
    """Obtém IDs dos usuários a manter"""
    cursor = conn.cursor()
    
    placeholders = ','.join(['%s'] * len(USERS_TO_KEEP))
    cursor.execute(f"""
        SELECT "Id", "Email", "Name", "LastName", "Role" 
        FROM "Users" 
        WHERE "Email" IN ({placeholders})
    """, USERS_TO_KEEP)
    
    users = {}
    for row in cursor.fetchall():
        users[row[1]] = {
            "id": str(row[0]),
            "name": row[2],
            "lastName": row[3],
            "role": row[4]
        }
    
    cursor.close()
    return users

def get_specialties(conn):
    """Obtém especialidades dos médicos"""
    cursor = conn.cursor()
    cursor.execute("""
        SELECT s."Id", s."Name", pp."UserId"
        FROM "Specialties" s
        JOIN "ProfessionalProfiles" pp ON pp."SpecialtyId" = s."Id"
        JOIN "Users" u ON u."Id" = pp."UserId"
        WHERE u."Email" IN ('med_aj@telecuidar.com', 'med_gt@telecuidar.com')
    """)
    
    specialties = {}
    for row in cursor.fetchall():
        specialties[str(row[2])] = {
            "id": str(row[0]),
            "name": row[1]
        }
    
    cursor.close()
    return specialties

def clean_database(conn, users):
    """Limpa dados desnecessários do banco"""
    cursor = conn.cursor()
    user_ids = [u["id"] for u in users.values()]
    placeholders = ','.join(['%s'] * len(user_ids))
    
    print("\n🧹 Limpando banco de dados...")
    
    # 1. Deletar consultas de usuários não mantidos
    cursor.execute(f"""
        DELETE FROM "Appointments" 
        WHERE "PatientId" NOT IN ({placeholders}) 
           OR "ProfessionalId" NOT IN ({placeholders})
    """, user_ids + user_ids)
    print(f"  - Consultas removidas: {cursor.rowcount}")
    
    # 2. Deletar prescrições órfãs
    cursor.execute("""
        DELETE FROM "Prescriptions" p
        WHERE NOT EXISTS (SELECT 1 FROM "Appointments" a WHERE a."Id" = p."AppointmentId")
    """)
    print(f"  - Prescrições órfãs removidas: {cursor.rowcount}")
    
    # 3. Deletar atestados órfãos
    cursor.execute("""
        DELETE FROM "MedicalCertificates" mc
        WHERE NOT EXISTS (SELECT 1 FROM "Appointments" a WHERE a."Id" = mc."AppointmentId")
    """)
    print(f"  - Atestados órfãos removidos: {cursor.rowcount}")
    
    # 4. Deletar anexos órfãos
    cursor.execute("""
        DELETE FROM "Attachments" att
        WHERE att."AppointmentId" IS NOT NULL 
          AND NOT EXISTS (SELECT 1 FROM "Appointments" a WHERE a."Id" = att."AppointmentId")
    """)
    print(f"  - Anexos órfãos removidos: {cursor.rowcount}")
    
    # 5. Deletar agendas de profissionais não mantidos
    cursor.execute(f"""
        DELETE FROM "Schedules" 
        WHERE "ProfessionalId" NOT IN ({placeholders})
    """, user_ids)
    print(f"  - Agendas removidas: {cursor.rowcount}")
    
    # 6. Deletar perfis de pacientes não mantidos
    cursor.execute(f"""
        DELETE FROM "PatientProfiles" 
        WHERE "UserId" NOT IN ({placeholders})
    """, user_ids)
    print(f"  - Perfis de pacientes removidos: {cursor.rowcount}")
    
    # 7. Deletar perfis de profissionais não mantidos
    cursor.execute(f"""
        DELETE FROM "ProfessionalProfiles" 
        WHERE "UserId" NOT IN ({placeholders})
    """, user_ids)
    print(f"  - Perfis profissionais removidos: {cursor.rowcount}")
    
    # 8. Deletar usuários não mantidos
    cursor.execute(f"""
        DELETE FROM "Users" 
        WHERE "Email" NOT IN ({','.join(['%s'] * len(USERS_TO_KEEP))})
    """, USERS_TO_KEEP)
    print(f"  - Usuários removidos: {cursor.rowcount}")
    
    # Agora limpar TODAS as consultas remanescentes para começar do zero
    cursor.execute('DELETE FROM "Appointments"')
    print(f"  - Todas consultas remanescentes removidas: {cursor.rowcount}")
    
    conn.commit()
    cursor.close()
    print("✅ Limpeza concluída!")

def create_biometrics_json(systolic=None, diastolic=None, heart_rate=None, temp=None, weight=None, spo2=None, glucose=None):
    """Cria JSON de sinais vitais"""
    data = {}
    
    if systolic and diastolic:
        data["bloodPressure"] = {"systolic": systolic, "diastolic": diastolic, "timestamp": datetime.now().isoformat()}
    if heart_rate:
        data["heartRate"] = {"value": heart_rate, "timestamp": datetime.now().isoformat()}
    if temp:
        data["temperature"] = {"value": temp, "timestamp": datetime.now().isoformat()}
    if weight:
        data["weight"] = {"value": weight, "timestamp": datetime.now().isoformat()}
    if spo2:
        data["oxygenSaturation"] = {"value": spo2, "timestamp": datetime.now().isoformat()}
    if glucose:
        data["bloodGlucose"] = {"value": glucose, "timestamp": datetime.now().isoformat()}
    
    return json.dumps(data) if data else None

def create_anamnesis_json(chief_complaint, history, medications=None, allergies=None):
    """Cria JSON de anamnese"""
    return json.dumps({
        "chiefComplaint": chief_complaint,
        "historyOfPresentIllness": history,
        "currentMedications": medications or [],
        "allergies": allergies or [],
        "reviewOfSystems": {},
        "familyHistory": "Sem histórico familiar relevante",
        "socialHistory": "Não tabagista, não etilista"
    })

def create_soap_json(subjective, objective, assessment, plan):
    """Cria JSON de notas SOAP"""
    return json.dumps({
        "subjective": subjective,
        "objective": objective,
        "assessment": assessment,
        "plan": plan
    })

def create_historical_appointments(conn, users, specialties):
    """Cria 4 consultas históricas com dados completos"""
    cursor = conn.cursor()
    
    patient = users["pac_dc@telecuidar.com"]
    assistant = users["enf_do@telecuidar.com"]
    med_aj = users["med_aj@telecuidar.com"]
    med_gt = users["med_gt@telecuidar.com"]
    
    print("\n📋 Criando consultas históricas...")
    
    # Consultas históricas - 2 para cada médico
    historical_data = [
        # Consulta 1 - Psiquiatria (15 dias atrás)
        {
            "date": datetime(2026, 1, 25),
            "time": time(9, 0),
            "professional": med_aj,
            "specialty_id": specialties[med_aj["id"]]["id"],
            "biometrics": create_biometrics_json(128, 82, 78, 36.5, 85.2, 98),
            "anamnesis": create_anamnesis_json(
                "Ansiedade e dificuldade para dormir",
                "Paciente relata episódios de ansiedade há 3 meses, com piora nas últimas semanas. Dificuldade para iniciar e manter o sono. Não apresenta ideação suicida.",
                ["Nenhuma medicação atual"],
                ["Penicilina"]
            ),
            "soap": create_soap_json(
                "Paciente refere ansiedade, insônia inicial e intermediária há 3 meses. Nega uso de substâncias.",
                "Paciente vigil, orientado, cooperativo. Humor ansioso, afeto congruente. Pensamento sem alterações de forma ou conteúdo.",
                "F41.1 - Transtorno de ansiedade generalizada",
                "1. Iniciar Escitalopram 10mg 1x/dia pela manhã\n2. Higiene do sono\n3. Retorno em 30 dias"
            ),
            "has_prescription": True,
            "prescription_items": [
                {"name": "Escitalopram 10mg", "dosage": "1 comprimido", "frequency": "1x ao dia, pela manhã", "duration": "30 dias", "qty": 30}
            ]
        },
        # Consulta 2 - Psiquiatria (7 dias atrás - retorno)
        {
            "date": datetime(2026, 2, 2),
            "time": time(10, 30),
            "professional": med_aj,
            "specialty_id": specialties[med_aj["id"]]["id"],
            "biometrics": create_biometrics_json(122, 78, 72, 36.4, 85.0, 99),
            "anamnesis": create_anamnesis_json(
                "Retorno - ansiedade",
                "Paciente retorna referindo melhora parcial da ansiedade após início do Escitalopram. Sono melhorou. Sem efeitos colaterais significativos.",
                ["Escitalopram 10mg"],
                ["Penicilina"]
            ),
            "soap": create_soap_json(
                "Retorno em 7 dias. Relata melhora de 50% da ansiedade, dormindo melhor. Sem náuseas ou outros efeitos adversos.",
                "Bom estado geral, menos ansioso que na consulta anterior. Afeto eutímico.",
                "F41.1 - Transtorno de ansiedade generalizada - em tratamento, com boa resposta",
                "1. Manter Escitalopram 10mg\n2. Avaliar aumento de dose no próximo retorno se necessário\n3. Retorno em 30 dias"
            ),
            "has_prescription": True,
            "prescription_items": [
                {"name": "Escitalopram 10mg", "dosage": "1 comprimido", "frequency": "1x ao dia, pela manhã", "duration": "30 dias", "qty": 30}
            ]
        },
        # Consulta 3 - Dermatologia (20 dias atrás)
        {
            "date": datetime(2026, 1, 20),
            "time": time(14, 0),
            "professional": med_gt,
            "specialty_id": specialties[med_gt["id"]]["id"],
            "biometrics": create_biometrics_json(125, 80, 75, 36.6, 85.2, 98),
            "anamnesis": create_anamnesis_json(
                "Manchas avermelhadas no rosto",
                "Paciente queixa-se de manchas avermelhadas na face há 2 meses, com descamação. Piora com exposição solar. Já usou hidratante sem melhora.",
                ["Protetor solar FPS 30"],
                ["Nenhuma alergia conhecida"]
            ),
            "soap": create_soap_json(
                "Manchas eritematosas em face há 2 meses, com descamação e fotossensibilidade.",
                "Placas eritematosas com descamação fina em região malar bilateral, poupando sulco nasolabial.",
                "L30.9 - Dermatite não especificada (suspeita de rosácea)",
                "1. Suspender uso de produtos irritantes\n2. Metronidazol gel 0,75% 2x/dia\n3. Protetor solar FPS 50\n4. Retorno em 30 dias"
            ),
            "has_prescription": True,
            "prescription_items": [
                {"name": "Metronidazol gel 0,75%", "dosage": "Aplicar fina camada", "frequency": "2x ao dia", "duration": "30 dias", "qty": 1},
                {"name": "Protetor solar FPS 50", "dosage": "Aplicar generosamente", "frequency": "Manhã e ao meio-dia", "duration": "Uso contínuo", "qty": 1}
            ],
            "has_certificate": True,
            "certificate_days": 1,
            "certificate_reason": "Necessidade de consulta médica e realização de exames dermatológicos"
        },
        # Consulta 4 - Dermatologia (5 dias atrás - retorno)
        {
            "date": datetime(2026, 2, 4),
            "time": time(15, 30),
            "professional": med_gt,
            "specialty_id": specialties[med_gt["id"]]["id"],
            "biometrics": create_biometrics_json(120, 76, 70, 36.5, 85.1, 99),
            "anamnesis": create_anamnesis_json(
                "Retorno - manchas no rosto",
                "Paciente retorna com melhora significativa das lesões. Usando metronidazol gel e protetor solar conforme orientação. Sem ardência ou irritação.",
                ["Metronidazol gel 0,75%", "Protetor solar FPS 50"],
                ["Nenhuma alergia conhecida"]
            ),
            "soap": create_soap_json(
                "Retorno após 2 semanas. Refere melhora de aproximadamente 70% das lesões. Aderente ao tratamento.",
                "Redução significativa do eritema e descamação. Pele da face com melhor textura.",
                "L71.9 - Rosácea - em tratamento, com boa evolução",
                "1. Manter Metronidazol gel por mais 30 dias\n2. Manter protetor solar\n3. Orientado sobre fatores desencadeantes (calor, bebidas quentes, álcool)\n4. Retorno em 60 dias"
            ),
            "has_prescription": True,
            "prescription_items": [
                {"name": "Metronidazol gel 0,75%", "dosage": "Aplicar fina camada", "frequency": "2x ao dia", "duration": "30 dias", "qty": 1}
            ]
        }
    ]
    
    for i, data in enumerate(historical_data, 1):
        appointment_id = str(uuid.uuid4())
        
        # Inserir consulta
        cursor.execute("""
            INSERT INTO "Appointments" (
                "Id", "PatientId", "ProfessionalId", "AssistantId", "SpecialtyId",
                "Date", "Time", "EndTime", "Type", "Status",
                "BiometricsJson", "AnamnesisJson", "SoapJson",
                "CheckInTime", "ConsultationStartedAt", "DoctorJoinedAt", "ConsultationEndedAt",
                "DurationInMinutes", "Observation", "CreatedAt", "UpdatedAt"
            ) VALUES (
                %s, %s, %s, %s, %s,
                %s, %s, %s, %s, %s,
                %s, %s, %s,
                %s, %s, %s, %s,
                %s, %s, %s, %s
            )
        """, (
            appointment_id,
            patient["id"],
            data["professional"]["id"],
            assistant["id"],
            data["specialty_id"],
            data["date"].date(),
            data["time"],
            (datetime.combine(data["date"].date(), data["time"]) + timedelta(minutes=30)).time(),
            1,  # Return
            6,  # Completed
            data["biometrics"],
            data["anamnesis"],
            data["soap"],
            data["date"] - timedelta(minutes=15),
            data["date"] - timedelta(minutes=10),
            data["date"],
            data["date"] + timedelta(minutes=25),
            25,
            "Consulta finalizada - POC Demo",
            datetime.now(),
            datetime.now()
        ))
        
        # Criar prescrição se existir
        if data.get("has_prescription"):
            prescription_id = str(uuid.uuid4())
            items_json = json.dumps(data["prescription_items"])
            
            cursor.execute("""
                INSERT INTO "Prescriptions" (
                    "Id", "AppointmentId", "PatientId", "ProfessionalId",
                    "ItemsJson", "SignedAt", "CreatedAt", "UpdatedAt"
                ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            """, (
                prescription_id,
                appointment_id,
                patient["id"],
                data["professional"]["id"],
                items_json,
                data["date"],  # SignedAt = data da consulta
                datetime.now(),
                datetime.now()
            ))
        
        # Criar atestado se existir
        if data.get("has_certificate"):
            cert_id = str(uuid.uuid4())
            
            cursor.execute("""
                INSERT INTO "MedicalCertificates" (
                    "Id", "AppointmentId", "PatientId", "ProfessionalId",
                    "Tipo", "DiasAfastamento", "Conteudo", "DataEmissao", "DataInicio", "DataFim",
                    "SignedAt", "CreatedAt", "UpdatedAt"
                ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            """, (
                cert_id,
                appointment_id,
                patient["id"],
                data["professional"]["id"],
                1,  # Tipo = Afastamento (enum: 0=Comparecimento, 1=Afastamento, 2=Aptidao, 3=Acompanhante, 4=Outro)
                data["certificate_days"],
                data["certificate_reason"],  # Conteudo
                data["date"],
                data["date"].date(),
                (data["date"] + timedelta(days=data["certificate_days"])).date(),
                data["date"],  # SignedAt
                datetime.now(),
                datetime.now()
            ))
        
        specialty_name = specialties[data["professional"]["id"]]["name"]
        print(f"  ✅ Consulta {i}: {data['date'].strftime('%d/%m/%Y')} - {specialty_name} (Dr. {data['professional']['name']}) - COMPLETED")
    
    conn.commit()
    cursor.close()
    print(f"📋 {len(historical_data)} consultas históricas criadas!")

def create_future_appointments(conn, users, specialties):
    """Cria consultas de 09/02 a 20/02/2026"""
    cursor = conn.cursor()
    
    patient = users["pac_dc@telecuidar.com"]
    assistant = users["enf_do@telecuidar.com"]
    med_aj = users["med_aj@telecuidar.com"]
    med_gt = users["med_gt@telecuidar.com"]
    
    print("\n📅 Criando consultas futuras (09/02 a 20/02)...")
    
    # Consultas agendadas
    appointments_schedule = [
        # Dia 09 (domingo - pulado)
        # Dia 10 (segunda) - Uma consulta às 09:00
        {"date": datetime(2026, 2, 10), "time": time(9, 0), "professional": med_gt, "status": 0},  # Scheduled
        # Dia 11 (terça) - Uma às 10:00
        {"date": datetime(2026, 2, 11), "time": time(10, 0), "professional": med_aj, "status": 0},  # Scheduled
        # Dia 12 (quarta - APRESENTAÇÃO) - Duas consultas, uma de cada médico
        {"date": datetime(2026, 2, 12), "time": time(9, 0), "professional": med_gt, "status": 0},  # Scheduled - Dermato
        {"date": datetime(2026, 2, 12), "time": time(10, 30), "professional": med_aj, "status": 0},  # Scheduled - Psiquiatria
        # Dia 13 (quinta) - Uma consulta
        {"date": datetime(2026, 2, 13), "time": time(14, 0), "professional": med_gt, "status": 0},  # Scheduled
        # Dia 16 (segunda) - Uma consulta
        {"date": datetime(2026, 2, 16), "time": time(9, 0), "professional": med_aj, "status": 0},  # Scheduled
        # Dia 17 (terça) - Uma consulta
        {"date": datetime(2026, 2, 17), "time": time(11, 0), "professional": med_gt, "status": 0},  # Scheduled
        # Dia 18 (quarta) - Uma consulta
        {"date": datetime(2026, 2, 18), "time": time(15, 0), "professional": med_aj, "status": 0},  # Scheduled
        # Dia 19 (quinta) - Uma consulta
        {"date": datetime(2026, 2, 19), "time": time(10, 0), "professional": med_gt, "status": 0},  # Scheduled
        # Dia 20 (sexta) - Uma consulta
        {"date": datetime(2026, 2, 20), "time": time(14, 0), "professional": med_aj, "status": 0},  # Scheduled
    ]
    
    for apt in appointments_schedule:
        appointment_id = str(uuid.uuid4())
        specialty_id = specialties[apt["professional"]["id"]]["id"]
        
        cursor.execute("""
            INSERT INTO "Appointments" (
                "Id", "PatientId", "ProfessionalId", "AssistantId", "SpecialtyId",
                "Date", "Time", "EndTime", "Type", "Status",
                "Observation", "CreatedAt", "UpdatedAt"
            ) VALUES (
                %s, %s, %s, %s, %s,
                %s, %s, %s, %s, %s,
                %s, %s, %s
            )
        """, (
            appointment_id,
            patient["id"],
            apt["professional"]["id"],
            assistant["id"],
            specialty_id,
            apt["date"].date(),
            apt["time"],
            (datetime.combine(apt["date"].date(), apt["time"]) + timedelta(minutes=30)).time(),
            0,  # FirstVisit
            apt["status"],
            f"Consulta agendada - Demo",
            datetime.now(),
            datetime.now()
        ))
        
        specialty_name = specialties[apt["professional"]["id"]]["name"]
        status_name = "AGENDADA" if apt["status"] == 0 else "CONFIRMADA"
        print(f"  📅 {apt['date'].strftime('%d/%m/%Y')} {apt['time'].strftime('%H:%M')} - {specialty_name} (Dr. {apt['professional']['name']}) - {status_name}")
    
    conn.commit()
    cursor.close()
    print(f"📅 {len(appointments_schedule)} consultas futuras criadas!")

def verify_schedules(conn, users):
    """Verifica se os médicos têm agendas configuradas"""
    cursor = conn.cursor()
    
    med_aj = users["med_aj@telecuidar.com"]
    med_gt = users["med_gt@telecuidar.com"]
    
    for med in [med_aj, med_gt]:
        cursor.execute("""
            SELECT "Id" FROM "Schedules" WHERE "ProfessionalId" = %s AND "IsActive" = 1
        """, (med["id"],))
        
        if not cursor.fetchone():
            print(f"⚠️ Criando agenda para Dr. {med['name']}...")
            
            global_config = json.dumps({
                "TimeRange": {"StartTime": "08:00", "EndTime": "18:00"},
                "ConsultationDuration": 30,
                "IntervalBetweenConsultations": 0
            })
            
            days_config = json.dumps([
                {"Day": "Monday", "IsWorking": True, "Customized": False},
                {"Day": "Tuesday", "IsWorking": True, "Customized": False},
                {"Day": "Wednesday", "IsWorking": True, "Customized": False},
                {"Day": "Thursday", "IsWorking": True, "Customized": False},
                {"Day": "Friday", "IsWorking": True, "Customized": False},
                {"Day": "Saturday", "IsWorking": False, "Customized": False},
                {"Day": "Sunday", "IsWorking": False, "Customized": False}
            ])
            
            cursor.execute("""
                INSERT INTO "Schedules" (
                    "Id", "ProfessionalId", "GlobalConfigJson", "DaysConfigJson",
                    "ValidityStartDate", "ValidityEndDate", "IsActive", "CreatedAt", "UpdatedAt"
                ) VALUES (%s, %s, %s, %s, %s, %s, 1, %s, %s)
            """, (
                str(uuid.uuid4()),
                med["id"],
                global_config,
                days_config,
                datetime(2026, 2, 1),
                datetime(2026, 3, 31),
                datetime.now(),
                datetime.now()
            ))
    
    conn.commit()
    cursor.close()

def print_summary(conn, users):
    """Imprime resumo do banco"""
    cursor = conn.cursor()
    
    print("\n" + "="*60)
    print("📊 RESUMO DO BANCO PREPARADO PARA DEMO")
    print("="*60)
    
    # Usuários
    print("\n👥 Usuários mantidos:")
    for email, user in users.items():
        role_names = {0: "Paciente", 1: "Profissional", 2: "Admin", 3: "Assistente", 4: "Regulador"}
        role = role_names.get(user.get("role", 0), user.get("role"))
        print(f"  - {email}: {user['name']} {user['lastName']} ({role})")
    
    # Consultas
    cursor.execute('SELECT COUNT(*) FROM "Appointments"')
    total = cursor.fetchone()[0]
    
    cursor.execute('SELECT COUNT(*) FROM "Appointments" WHERE "Status" = 6')  # Completed
    completed = cursor.fetchone()[0]
    
    cursor.execute('SELECT COUNT(*) FROM "Appointments" WHERE "Status" = 0')  # Scheduled
    scheduled = cursor.fetchone()[0]
    
    print(f"\n📋 Consultas:")
    print(f"  - Total: {total}")
    print(f"  - Históricas (Completed): {completed}")
    print(f"  - Agendadas (Scheduled): {scheduled}")
    
    # Prescrições e atestados
    cursor.execute('SELECT COUNT(*) FROM "Prescriptions"')
    prescriptions = cursor.fetchone()[0]
    
    cursor.execute('SELECT COUNT(*) FROM "MedicalCertificates"')
    certificates = cursor.fetchone()[0]
    
    print(f"\n📄 Documentos:")
    print(f"  - Receitas: {prescriptions}")
    print(f"  - Atestados: {certificates}")
    
    print("\n" + "="*60)
    print("✅ Banco pronto para apresentação em 12/02/2026!")
    print("="*60)
    print("\n🔐 Credenciais de teste (senha: 123):")
    print("  - Paciente: pac_dc@telecuidar.com (Daniel Carrara)")
    print("  - Médico Psiquiatria: med_aj@telecuidar.com (Antônio Jorge)")
    print("  - Médico Dermatologia: med_gt@telecuidar.com (Geraldo Tadeu)")
    print("  - Enfermeira: enf_do@telecuidar.com (Daniela Ochoa)")
    print("  - Recepcionista: rec_ma@telecuidar.com (Maria Atendimento)")
    print("  - Admin: adm_ca@telecuidar.com (Cláudio Amantino)")
    print("  - Regulador: reg_go@telecuidar.com")
    
    cursor.close()

def main():
    print("🏥 TeleCuidar - Preparação do Banco para Demo")
    print("📅 Apresentação: 12/02/2026")
    print("-" * 50)
    
    try:
        conn = get_connection()
        print("✅ Conectado ao PostgreSQL")
        
        # 1. Obter IDs dos usuários a manter
        users = get_users_ids(conn)
        if len(users) < 7:
            print(f"❌ Erro: Esperados 7 usuários, encontrados {len(users)}")
            print("Usuários encontrados:", list(users.keys()))
            return
        
        print(f"✅ {len(users)} usuários identificados")
        
        # 2. Obter especialidades
        specialties = get_specialties(conn)
        print(f"✅ {len(specialties)} especialidades identificadas")
        
        # 3. Limpar banco
        clean_database(conn, users)
        
        # 4. Verificar/criar agendas
        verify_schedules(conn, users)
        
        # 5. Criar consultas históricas
        create_historical_appointments(conn, users, specialties)
        
        # 6. Criar consultas futuras
        create_future_appointments(conn, users, specialties)
        
        # 7. Resumo
        print_summary(conn, users)
        
        conn.close()
        
    except psycopg2.Error as e:
        print(f"❌ Erro de banco de dados: {e}")
    except Exception as e:
        print(f"❌ Erro: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main()
