-- ============================================================
-- SCRIPT PARA ADICIONAR BIOMÉTRICOS E DADOS CLÍNICOS DETALHADOS
-- POC TELECUIDAR - 24/01/2026
-- ============================================================

-- Pacientes e seus perfis de saúde:
-- Daniel Carrara (71E0E646): Ansiedade, palpitações - jovem saudável
-- Maria Silva (F764F4E1): Hipertensa idosa
-- João Santos (AE637012): Transtorno de pânico - jovem
-- Ana Oliveira (BA040C1B): Gestante
-- Pedro Costa (E7657BF8): Diabético tipo 2
-- Lúcia Ferreira (903F9074): Depressão grave - idosa

-- ============================================================
-- ATUALIZAR BIOMÉTRICOS DAS CONSULTAS REALIZADAS
-- ============================================================

-- Daniel Carrara - Check-up dezembro (saudável, leve ansiedade)
UPDATE Appointments SET BiometricsJson = '{"heartRate":72,"bloodPressureSystolic":122,"bloodPressureDiastolic":78,"oxygenSaturation":98,"temperature":36.4,"respiratoryRate":16,"glucose":92,"weight":78.5,"height":1.78,"lastUpdated":"2025-12-15T10:30:00"}'
WHERE Id = '9BA1FF25-71CE-44BE-A18F-71ECA2E39282';

-- Daniel Carrara - Consulta cardiológica janeiro (palpitações)
UPDATE Appointments SET BiometricsJson = '{"heartRate":88,"bloodPressureSystolic":130,"bloodPressureDiastolic":85,"oxygenSaturation":97,"temperature":36.5,"respiratoryRate":18,"glucose":95,"weight":78.2,"height":1.78,"lastUpdated":"2026-01-05T09:15:00"}'
WHERE Id = '7815A758-5E15-4B86-B0CB-2A5AF007F643';

-- Daniel Carrara - Retorno cardiológico (melhora)
UPDATE Appointments SET BiometricsJson = '{"heartRate":72,"bloodPressureSystolic":125,"bloodPressureDiastolic":80,"oxygenSaturation":98,"temperature":36.3,"respiratoryRate":15,"glucose":90,"weight":78.0,"height":1.78,"lastUpdated":"2026-01-10T10:15:00"}'
WHERE Id = '2FCA8FFE-EC90-4BA3-A4F9-AF28D64D9220';

-- Daniel Carrara - Consulta psiquiátrica (ansiedade)
UPDATE Appointments SET BiometricsJson = '{"heartRate":92,"bloodPressureSystolic":135,"bloodPressureDiastolic":88,"oxygenSaturation":97,"temperature":36.6,"respiratoryRate":20,"glucose":88,"weight":77.8,"height":1.78,"lastUpdated":"2026-01-12T14:30:00"}'
WHERE Id = '7F5E0A3E-7D24-440C-BE35-1A6983C25B89';

-- Daniel Carrara - Seguimento cardiológico
UPDATE Appointments SET BiometricsJson = '{"heartRate":68,"bloodPressureSystolic":120,"bloodPressureDiastolic":78,"oxygenSaturation":99,"temperature":36.4,"respiratoryRate":14,"glucose":91,"weight":77.5,"height":1.78,"lastUpdated":"2026-01-17T09:30:00"}'
WHERE Id = '42DF3E58-7995-424D-A85A-16EEB450CD64';

-- Daniel Carrara - Seguimento TAG
UPDATE Appointments SET BiometricsJson = '{"heartRate":70,"bloodPressureSystolic":118,"bloodPressureDiastolic":76,"oxygenSaturation":98,"temperature":36.3,"respiratoryRate":14,"glucose":89,"weight":77.2,"height":1.78,"lastUpdated":"2026-01-23T15:30:00"}'
WHERE Id = '19191513-7611-4B00-99E0-0AB4A1B67BA5';

-- Maria Silva - Ajuste HAS dezembro (hipertensa, pressão elevada)
UPDATE Appointments SET BiometricsJson = '{"heartRate":78,"bloodPressureSystolic":145,"bloodPressureDiastolic":92,"oxygenSaturation":96,"temperature":36.2,"respiratoryRate":18,"glucose":108,"weight":72.0,"height":1.58,"lastUpdated":"2025-12-18T10:30:00"}'
WHERE Id = '9A876D14-92B1-4943-92B7-C0C08A01D923';

-- Maria Silva - Controle HAS janeiro
UPDATE Appointments SET BiometricsJson = '{"heartRate":72,"bloodPressureSystolic":135,"bloodPressureDiastolic":85,"oxygenSaturation":97,"temperature":36.3,"respiratoryRate":16,"glucose":102,"weight":71.8,"height":1.58,"lastUpdated":"2026-01-06T08:30:00"}'
WHERE Id = 'ADC227DF-9C3B-498A-A92D-B1BB0DA3B91B';

-- Maria Silva - Reavaliação HAS
UPDATE Appointments SET BiometricsJson = '{"heartRate":70,"bloodPressureSystolic":125,"bloodPressureDiastolic":78,"oxygenSaturation":97,"temperature":36.4,"respiratoryRate":15,"glucose":98,"weight":71.5,"height":1.58,"lastUpdated":"2026-01-13T09:45:00"}'
WHERE Id = 'E705B3BA-0E09-4D10-9BFA-94DFCFE1EAF1';

-- Maria Silva - Controle mensal
UPDATE Appointments SET BiometricsJson = '{"heartRate":68,"bloodPressureSystolic":128,"bloodPressureDiastolic":82,"oxygenSaturation":97,"temperature":36.2,"respiratoryRate":16,"glucose":100,"weight":71.2,"height":1.58,"lastUpdated":"2026-01-18T08:45:00"}'
WHERE Id = '1D5C535A-902B-4A41-A754-2830510D1160';

-- Maria Silva - Avaliação insônia
UPDATE Appointments SET BiometricsJson = '{"heartRate":74,"bloodPressureSystolic":132,"bloodPressureDiastolic":84,"oxygenSaturation":96,"temperature":36.3,"respiratoryRate":17,"glucose":105,"weight":71.0,"height":1.58,"lastUpdated":"2026-01-11T16:15:00"}'
WHERE Id = '561F08B5-6DCD-47E4-BCA4-1F93FED65A9B';

-- João Santos - Início tratamento pânico dezembro
UPDATE Appointments SET BiometricsJson = '{"heartRate":98,"bloodPressureSystolic":140,"bloodPressureDiastolic":90,"oxygenSaturation":97,"temperature":36.8,"respiratoryRate":24,"glucose":110,"weight":82.0,"height":1.75,"lastUpdated":"2025-12-20T15:30:00"}'
WHERE Id = '0FBB3E67-D948-478F-99BB-4B42D1F86102';

-- João Santos - Primeira consulta pânico
UPDATE Appointments SET BiometricsJson = '{"heartRate":95,"bloodPressureSystolic":138,"bloodPressureDiastolic":88,"oxygenSaturation":97,"temperature":36.7,"respiratoryRate":22,"glucose":105,"weight":81.5,"height":1.75,"lastUpdated":"2026-01-07T15:30:00"}'
WHERE Id = '028DBAD0-2E50-430A-A1A3-8D20C6BF1F28';

-- João Santos - Retorno pânico (melhora)
UPDATE Appointments SET BiometricsJson = '{"heartRate":76,"bloodPressureSystolic":128,"bloodPressureDiastolic":82,"oxygenSaturation":98,"temperature":36.5,"respiratoryRate":16,"glucose":98,"weight":81.0,"height":1.75,"lastUpdated":"2026-01-14T16:30:00"}'
WHERE Id = 'C9FB6D4A-531E-43E9-A423-5931F93E3FFD';

-- João Santos - Liberação academia
UPDATE Appointments SET BiometricsJson = '{"heartRate":68,"bloodPressureSystolic":118,"bloodPressureDiastolic":72,"oxygenSaturation":99,"temperature":36.4,"respiratoryRate":14,"glucose":92,"weight":80.5,"height":1.75,"lastUpdated":"2026-01-15T08:30:00"}'
WHERE Id = '5D5ECF04-41D0-4613-8FF4-54343D54E654';

-- João Santos - Manutenção ansiedade
UPDATE Appointments SET BiometricsJson = '{"heartRate":70,"bloodPressureSystolic":120,"bloodPressureDiastolic":76,"oxygenSaturation":98,"temperature":36.3,"respiratoryRate":15,"glucose":94,"weight":80.0,"height":1.75,"lastUpdated":"2026-01-19T14:30:00"}'
WHERE Id = '7F9989B8-B5D9-491D-ADF1-7EB3ED904FF2';

-- Ana Oliveira - Primeira consulta gestante dezembro
UPDATE Appointments SET BiometricsJson = '{"heartRate":88,"bloodPressureSystolic":108,"bloodPressureDiastolic":68,"oxygenSaturation":98,"temperature":36.6,"respiratoryRate":18,"glucose":85,"weight":65.0,"height":1.62,"lastUpdated":"2025-12-22T11:30:00"}'
WHERE Id = 'C62C5612-05CC-437B-8A53-66A5D3C6A1F0';

-- Ana Oliveira - Avaliação cardio gestacional
UPDATE Appointments SET BiometricsJson = '{"heartRate":82,"bloodPressureSystolic":110,"bloodPressureDiastolic":70,"oxygenSaturation":98,"temperature":36.5,"respiratoryRate":17,"glucose":88,"weight":66.5,"height":1.62,"lastUpdated":"2026-01-08T11:30:00"}'
WHERE Id = 'CECCDB6C-CC87-439B-8238-1883FBABC740';

-- Ana Oliveira - Seguimento gestação
UPDATE Appointments SET BiometricsJson = '{"heartRate":84,"bloodPressureSystolic":108,"bloodPressureDiastolic":68,"oxygenSaturation":98,"temperature":36.4,"respiratoryRate":16,"glucose":82,"weight":68.0,"height":1.62,"lastUpdated":"2026-01-20T10:30:00"}'
WHERE Id = '3C8FAB75-8E28-4FF8-9F0C-DB5D74D2358D';

-- Ana Oliveira - Ansiedade gestacional
UPDATE Appointments SET BiometricsJson = '{"heartRate":90,"bloodPressureSystolic":112,"bloodPressureDiastolic":72,"oxygenSaturation":97,"temperature":36.7,"respiratoryRate":19,"glucose":86,"weight":68.2,"height":1.62,"lastUpdated":"2026-01-18T14:30:00"}'
WHERE Id = '6ECACC73-9EC2-4B76-8948-3AC89714BC2C';

-- Pedro Costa - Avaliação DM dezembro
UPDATE Appointments SET BiometricsJson = '{"heartRate":76,"bloodPressureSystolic":142,"bloodPressureDiastolic":90,"oxygenSaturation":96,"temperature":36.5,"respiratoryRate":17,"glucose":156,"weight":92.0,"height":1.72,"lastUpdated":"2025-12-28T14:30:00"}'
WHERE Id = '6F65F999-198B-405E-834D-5036DED973AB';

-- Pedro Costa - Avaliação cardiovascular DM
UPDATE Appointments SET BiometricsJson = '{"heartRate":74,"bloodPressureSystolic":138,"bloodPressureDiastolic":88,"oxygenSaturation":96,"temperature":36.4,"respiratoryRate":16,"glucose":148,"weight":91.5,"height":1.72,"lastUpdated":"2026-01-09T14:45:00"}'
WHERE Id = '3AE49CF2-3991-4CEA-B82F-6999873D244B';

-- Pedro Costa - Retorno com exames
UPDATE Appointments SET BiometricsJson = '{"heartRate":72,"bloodPressureSystolic":128,"bloodPressureDiastolic":82,"oxygenSaturation":97,"temperature":36.3,"respiratoryRate":15,"glucose":132,"weight":90.8,"height":1.72,"lastUpdated":"2026-01-16T15:30:00"}'
WHERE Id = '9EF50898-1B84-4B3A-92A4-4D98ADA8FBB0';

-- Pedro Costa - Controle DM/HAS
UPDATE Appointments SET BiometricsJson = '{"heartRate":70,"bloodPressureSystolic":126,"bloodPressureDiastolic":80,"oxygenSaturation":97,"temperature":36.4,"respiratoryRate":15,"glucose":118,"weight":90.2,"height":1.72,"lastUpdated":"2026-01-21T14:30:00"}'
WHERE Id = '16E81A55-7410-4895-8B73-FAD28E8A1CF2';

-- Pedro Costa - Rastreio depressão
UPDATE Appointments SET BiometricsJson = '{"heartRate":68,"bloodPressureSystolic":124,"bloodPressureDiastolic":78,"oxygenSaturation":97,"temperature":36.3,"respiratoryRate":14,"glucose":122,"weight":89.8,"height":1.72,"lastUpdated":"2026-01-19T11:30:00"}'
WHERE Id = 'CC3F489F-4531-4A0C-98D4-28D058C0E3FF';

-- Lúcia Ferreira - Primeira consulta depressão dezembro
UPDATE Appointments SET BiometricsJson = '{"heartRate":82,"bloodPressureSystolic":130,"bloodPressureDiastolic":82,"oxygenSaturation":95,"temperature":36.1,"respiratoryRate":18,"glucose":95,"weight":58.0,"height":1.55,"lastUpdated":"2025-12-30T10:45:00"}'
WHERE Id = 'B12A0B5B-BFBF-4845-9F26-15B8557E139C';

-- Lúcia Ferreira - Avaliação depressão grave
UPDATE Appointments SET BiometricsJson = '{"heartRate":78,"bloodPressureSystolic":128,"bloodPressureDiastolic":80,"oxygenSaturation":95,"temperature":36.0,"respiratoryRate":17,"glucose":92,"weight":57.5,"height":1.55,"lastUpdated":"2026-01-08T10:45:00"}'
WHERE Id = 'CC218030-FFA3-4C16-A541-E3E531DADBB4';

-- Lúcia Ferreira - Retorno depressão
UPDATE Appointments SET BiometricsJson = '{"heartRate":74,"bloodPressureSystolic":125,"bloodPressureDiastolic":78,"oxygenSaturation":96,"temperature":36.2,"respiratoryRate":16,"glucose":94,"weight":58.2,"height":1.55,"lastUpdated":"2026-01-15T11:30:00"}'
WHERE Id = 'E0A037C7-1D6C-4D31-AC20-F8DDB44BC0B6';

-- Lúcia Ferreira - Melhora depressão
UPDATE Appointments SET BiometricsJson = '{"heartRate":70,"bloodPressureSystolic":122,"bloodPressureDiastolic":76,"oxygenSaturation":97,"temperature":36.3,"respiratoryRate":15,"glucose":90,"weight":59.0,"height":1.55,"lastUpdated":"2026-01-22T10:30:00"}'
WHERE Id = 'E1194F79-CA05-479C-A381-32615CAB4C57';

-- Lúcia Ferreira - Avaliação cardio palpitações
UPDATE Appointments SET BiometricsJson = '{"heartRate":86,"bloodPressureSystolic":128,"bloodPressureDiastolic":80,"oxygenSaturation":96,"temperature":36.4,"respiratoryRate":17,"glucose":92,"weight":58.8,"height":1.55,"lastUpdated":"2026-01-20T15:30:00"}'
WHERE Id = 'FDF34B8F-EB30-49AE-A8D7-9E3DE132289B';

-- ============================================================
-- ENRIQUECER ANAMNESE DAS CONSULTAS COM CAMPOS ADICIONAIS
-- ============================================================

-- Daniel Carrara - Primeira consulta cardio (mais detalhes)
UPDATE Appointments SET AnamnesisJson = '{
  "queixaPrincipal": "Palpitações esporádicas",
  "historiaDoencaAtual": "Paciente relata palpitações há 2 meses, principalmente após esforço físico ou consumo de café. Episódios duram de 5 a 15 minutos. Nega dor precordial, dispneia ou síncope. Associa início dos sintomas com período de maior estresse no trabalho.",
  "historicoFamiliar": "Pai faleceu de infarto agudo do miocárdio aos 65 anos. Mãe hipertensa em tratamento. Irmão saudável.",
  "historicoPatologico": "Nega comorbidades prévias. Nega internações anteriores. Cirurgias: apendicectomia aos 15 anos.",
  "medicamentosEmUso": "Nenhum medicamento de uso contínuo",
  "alergias": "Dipirona - apresenta urticária",
  "habitosVida": "Sedentário, consumo elevado de café (5-6 xícaras/dia), não tabagista, etilista social",
  "revisaoSistemas": "Sono irregular, 5-6h por noite. Nega alterações urinárias, gastrointestinais ou neurológicas."
}'
WHERE Id = '7815A758-5E15-4B86-B0CB-2A5AF007F643';

-- Maria Silva - Consulta HAS com mais detalhes
UPDATE Appointments SET AnamnesisJson = '{
  "queixaPrincipal": "Controle de pressão alta",
  "historiaDoencaAtual": "Hipertensa há 15 anos, em uso regular de medicação. Refere bom controle domiciliar nos últimos meses. Aferições em casa entre 130-140/80-90 mmHg. Nega cefaleia, tontura ou alterações visuais.",
  "historicoFamiliar": "Pai e mãe hipertensos. Pai teve AVC aos 70 anos. Mãe diabética tipo 2.",
  "historicoPatologico": "HAS diagnosticada há 15 anos. Dislipidemia em tratamento. Nega DM. Menopausa aos 52 anos.",
  "medicamentosEmUso": "Losartana 50mg 1x/dia, Anlodipino 5mg 1x/dia, Sinvastatina 20mg à noite",
  "alergias": "Penicilina - edema de glote aos 30 anos",
  "habitosVida": "Caminhadas 3x/semana, 30 minutos. Dieta com restrição de sal. Não tabagista. Não etilista.",
  "revisaoSistemas": "Insônia eventual. Constipação intestinal leve. Nega dispneia, edema ou dor torácica."
}'
WHERE Id = 'ADC227DF-9C3B-498A-A92D-B1BB0DA3B91B';

-- João Santos - Transtorno de pânico detalhado
UPDATE Appointments SET AnamnesisJson = '{
  "queixaPrincipal": "Crises de ansiedade intensas",
  "historiaDoencaAtual": "Paciente jovem com crises de pânico há 3 meses. Descreve episódios súbitos de taquicardia, sudorese profusa, tremores, sensação de sufocamento e medo intenso de morrer. Crises duram 15-30 minutos. Frequência: 2-3x por semana. Desenvolveu evitação de locais fechados e transporte público. Prejuízo funcional moderado no trabalho.",
  "historicoFamiliar": "Tia materna com síndrome do pânico em tratamento. Avó com depressão.",
  "historicoPatologico": "Nega comorbidades prévias. Nega internações psiquiátricas. Uso pregresso de maconha na adolescência.",
  "medicamentosEmUso": "Nenhum",
  "alergias": "Nega alergias conhecidas",
  "habitosVida": "Trabalha como programador, 10h/dia sentado. Sedentário. Consumo moderado de café. Não tabagista. Etilista social.",
  "revisaoSistemas": "Insônia inicial há 2 meses. Perda de apetite. Dificuldade de concentração. Nega alterações gastrointestinais."
}'
WHERE Id = '028DBAD0-2E50-430A-A1A3-8D20C6BF1F28';

-- Ana Oliveira - Gestante detalhada
UPDATE Appointments SET AnamnesisJson = '{
  "queixaPrincipal": "Avaliação cardíaca na gestação",
  "historiaDoencaAtual": "Gestante 20 semanas (G1P0A0), encaminhada pelo obstetra para avaliação de sopro cardíaco detectado em consulta de pré-natal. Assintomática do ponto de vista cardiovascular. Nega dispneia, palpitações, síncope ou edema.",
  "historicoFamiliar": "Sem cardiopatias na família. Mãe teve pré-eclâmpsia na primeira gestação.",
  "historicoPatologico": "Hígida previamente. Gestação planejada. Pré-natal iniciado com 8 semanas. Ultrassons morfológicos normais.",
  "medicamentosEmUso": "Ácido fólico 5mg/dia, Sulfato ferroso 40mg/dia, Polivitamínico gestacional",
  "alergias": "Nega alergias conhecidas",
  "habitosVida": "Nutricionista, alimentação balanceada. Yoga 2x/semana. Não tabagista. Abstêmia desde início da gestação.",
  "revisaoSistemas": "Náuseas leves no primeiro trimestre, já resolvidas. Movimentos fetais presentes. Nega sangramentos ou perdas.",
  "obstetrico": "G1P0A0. DUM: 15/08/2025. IG: 20 semanas. DPP: 22/05/2026."
}'
WHERE Id = 'CECCDB6C-CC87-439B-8238-1883FBABC740';

-- Pedro Costa - Diabético detalhado
UPDATE Appointments SET AnamnesisJson = '{
  "queixaPrincipal": "Check-up cardiovascular",
  "historiaDoencaAtual": "Diabético tipo 2 há 10 anos, encaminhado pelo endocrinologista para estratificação de risco cardiovascular. Bom controle glicêmico recente, HbA1c 7.2% há 3 meses. Nega dor torácica, dispneia ou claudicação.",
  "historicoFamiliar": "Pai diabético, faleceu de AVC aos 68 anos. Mãe hipertensa. Irmã com DM2.",
  "historicoPatologico": "DM2 há 10 anos. Dislipidemia. Sobrepeso. Retinopatia diabética não proliferativa leve. Neuropatia sensitiva leve em pés.",
  "medicamentosEmUso": "Metformina 850mg 2x/dia, Glibenclamida 5mg antes do café, AAS 100mg/dia, Atorvastatina 20mg à noite",
  "alergias": "Nega alergias conhecidas",
  "habitosVida": "Comerciante, sedentário por jornada de trabalho. Dieta irregular. Ex-tabagista (parou há 5 anos, 20 maços-ano). Etilista social.",
  "revisaoSistemas": "Poliúria e polidipsia controladas. Formigamento em pés. Nega alterações visuais recentes. Nega edema.",
  "exameLaboratorial": "Glicemia jejum: 126mg/dL, HbA1c: 7.2%, Colesterol total: 198mg/dL, LDL: 118mg/dL, HDL: 42mg/dL, Triglicérides: 186mg/dL, Creatinina: 0.9mg/dL"
}'
WHERE Id = '3AE49CF2-3991-4CEA-B82F-6999873D244B';

-- Lúcia Ferreira - Depressão detalhada
UPDATE Appointments SET AnamnesisJson = '{
  "queixaPrincipal": "Tristeza profunda e desânimo",
  "historiaDoencaAtual": "Paciente 60 anos, viúva há 1 ano (esposo faleceu de câncer). Tristeza persistente há 8 meses com piora progressiva. Choro fácil, isolamento social, abandono de atividades que antes davam prazer. Insônia terminal (acorda às 4h e não consegue dormir). Perda de peso de 5kg em 3 meses. Ideação de morte passiva: \"seria bom dormir e não acordar\". Nega planejamento ou tentativa de suicídio.",
  "historicoFamiliar": "Mãe teve depressão grave, tratou com internação. Irmã usa antidepressivo.",
  "historicoPatologico": "HAS em tratamento. Episódio depressivo leve há 20 anos, tratou por 1 ano. Menopausa aos 50 anos. Osteopenia.",
  "medicamentosEmUso": "Losartana 50mg/dia, Cálcio + Vitamina D",
  "alergias": "Sulfa - reação cutânea grave",
  "habitosVida": "Aposentada, mora sozinha. Antes ativa, agora não sai de casa. Alimentação pobre. Não tabagista. Não etilista.",
  "revisaoSistemas": "Insônia terminal grave. Inapetência. Constipação. Fadiga intensa. Dificuldade de concentração e memória.",
  "avaliacaoRisco": "PHQ-9: 22 (depressão grave). Ideação passiva de morte. Sem planejamento suicida. Apoio familiar presente (filha)."
}'
WHERE Id = 'CC218030-FFA3-4C16-A541-E3E531DADBB4';

-- ============================================================
-- ATUALIZAR SOAP DAS CONSULTAS COM MAIS DETALHES
-- ============================================================

-- Daniel Carrara - SOAP detalhado
UPDATE Appointments SET SoapJson = '{
  "subjetivo": "Paciente queixa-se de palpitações após esforço físico há 2 meses. Associa com consumo excessivo de café. Nega dor torácica, dispneia ou síncope. Refere estresse no trabalho e sono irregular.",
  "objetivo": "Bom estado geral, corado, hidratado, afebril. PA: 130/85 mmHg, FC: 78 bpm regular, FR: 16 irpm, SatO2: 98%. Ausculta cardíaca: bulhas rítmicas, normofonéticas, sem sopros. Ausculta pulmonar: murmúrio vesicular presente bilateralmente, sem ruídos adventícios. Extremidades: pulsos periféricos presentes e simétricos, sem edema.",
  "avaliacao": "Palpitações a esclarecer. Hipóteses: 1) Extrassístoles relacionadas a cafeína e estresse; 2) Arritmia a investigar. Estratificação de risco cardiovascular: baixo risco.",
  "plano": "1. Solicitar ECG de repouso\\n2. Solicitar Holter 24h\\n3. Orientar redução de cafeína (máximo 2 xícaras/dia)\\n4. Higiene do sono\\n5. Retorno em 15 dias com exames"
}'
WHERE Id = '7815A758-5E15-4B86-B0CB-2A5AF007F643';

-- Maria Silva - SOAP detalhado
UPDATE Appointments SET SoapJson = '{
  "subjetivo": "Paciente em acompanhamento de HAS. Refere adesão medicamentosa adequada. Aferições domiciliares entre 130-140/80-90 mmHg. Nega cefaleia, tontura, dispneia ou edema. Mantém caminhadas regulares.",
  "objetivo": "Bom estado geral, corada, hidratada. PA: 135/85 mmHg (sentada, MSD), FC: 68 bpm regular, Peso: 72kg, IMC: 28.8 kg/m². Ausculta cardíaca: bulhas rítmicas, normofonéticas, B4 presente. Ausculta pulmonar: limpa. MMII: sem edema, pulsos presentes.",
  "avaliacao": "Hipertensão arterial sistêmica estágio 1, controlada com terapia dupla. Sobrepeso. Dislipidemia em tratamento.",
  "plano": "1. Manter Losartana 50mg e Anlodipino 5mg\\n2. Manter Sinvastatina 20mg\\n3. Reforçar dieta hipossódica e DASH\\n4. Manter atividade física\\n5. Solicitar perfil lipídico e função renal\\n6. Retorno em 3 meses"
}'
WHERE Id = 'ADC227DF-9C3B-498A-A92D-B1BB0DA3B91B';

-- João Santos - SOAP detalhado
UPDATE Appointments SET SoapJson = '{
  "subjetivo": "Crises de pânico típicas há 3 meses, com frequência de 2-3x por semana. Descreve taquicardia, sudorese, tremores, dispneia e medo intenso de morrer durante episódios que duram 15-30 minutos. Desenvolveu agorafobia: evita transporte público e locais fechados. Prejuízo no trabalho por faltas e dificuldade de concentração.",
  "objetivo": "Vigil, orientado em tempo e espaço, ansioso durante consulta. Hipervigilante. Taquicárdico leve (88bpm). Mãos frias e sudoreicas. Sem tremores no momento. Humor ansioso, afeto congruente. Pensamento lógico, sem alterações do conteúdo. Sem sintomas psicóticos. Nega ideação suicida.",
  "avaliacao": "Transtorno de Pânico (F41.0) com agorafobia. Gravidade moderada a grave pelo prejuízo funcional. PHQ-9: 12 (depressão leve associada). GAD-7: 18 (ansiedade grave).",
  "plano": "1. Iniciar Sertralina 50mg pela manhã (titular até 100-150mg)\\n2. Clonazepam 0,5mg sublingual SOS (máximo 2x/dia por 4 semanas)\\n3. Encaminhar para psicoterapia TCC urgente\\n4. Psicoeducação sobre transtorno de pânico\\n5. Técnicas de respiração diafragmática\\n6. Retorno em 15 dias para avaliação de tolerância"
}'
WHERE Id = '028DBAD0-2E50-430A-A1A3-8D20C6BF1F28';

-- ============================================================
-- FIM DO SCRIPT DE BIOMÉTRICOS
-- ============================================================
