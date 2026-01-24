-- ============================================================
-- SCRIPT PARA COMPLETAR ANAMNESES - POC TELECUIDAR
-- 24/01/2026
-- ============================================================
-- Adiciona dados completos de antecedentes a todas as consultas
-- ============================================================

-- ============================================================
-- DANIEL CARRARA (71E0E646-73FA-4838-B73B-9E9C9CAAB4BA)
-- Jovem com palpitações/ansiedade
-- ============================================================

-- 05/01/2026 - Consulta cardiológica
UPDATE Appointments SET AnamnesisJson = '{"chiefComplaint":"Palpitações esporádicas","presentIllnessHistory":"Paciente relata palpitações há 2 meses, principalmente após esforço físico ou consumo de café. Episódios duram de 5 a 15 minutos. Nega dor torácica, dispneia ou síncope.","pastMedicalHistory":"Apendicectomia aos 15 anos. Nega internações clínicas.","familyHistory":"Pai faleceu de IAM aos 65 anos. Mãe hipertensa em tratamento. Irmão hígido.","personalHistory":{"previousDiseases":"Nega comorbidades","surgeries":"Apendicectomia (2012)","hospitalizations":"Apenas para cirurgia acima","allergies":"Dipirona - urticária","currentMedications":"Nenhum uso contínuo","vaccinations":"Esquema vacinal completo"},"lifestyle":{"diet":"Irregular, alto consumo de café","physicalActivity":"Sedentário","smoking":"Nunca fumou","alcohol":"Social, fins de semana","drugs":"Nega","sleep":"Irregular, 5-6h/noite"}}'
WHERE Id = '7815A758-5E15-4B86-B0CB-2A5AF007F643';

-- 10/01/2026 - Retorno com exames
UPDATE Appointments SET AnamnesisJson = '{"chiefComplaint":"Retorno com exames - Holter e ECG","presentIllnessHistory":"Traz ECG e Holter 24h. Refere melhora das palpitações após redução do consumo de café. Mantém episódios esporádicos de menor intensidade.","pastMedicalHistory":"Apendicectomia aos 15 anos. Nega internações clínicas.","familyHistory":"Pai faleceu de IAM aos 65 anos. Mãe hipertensa em tratamento. Irmão hígido.","personalHistory":{"previousDiseases":"Nega comorbidades","surgeries":"Apendicectomia (2012)","hospitalizations":"Apenas para cirurgia acima","allergies":"Dipirona - urticária","currentMedications":"Nenhum uso contínuo","vaccinations":"Esquema vacinal completo"},"lifestyle":{"diet":"Reduziu café para 2 xícaras/dia","physicalActivity":"Iniciou caminhadas","smoking":"Nunca fumou","alcohol":"Social moderado","drugs":"Nega","sleep":"Melhorando, 6-7h/noite"}}'
WHERE Id = '2FCA8FFE-EC90-4BA3-A4F9-AF28D64D9220';

-- 12/01/2026 - Consulta psiquiátrica (ansiedade)
UPDATE Appointments SET AnamnesisJson = '{"chiefComplaint":"Ansiedade e dificuldade para dormir","presentIllnessHistory":"Paciente relata ansiedade há 6 meses, com piora nos últimos 2 meses. Insônia inicial. Encaminhado pelo cardiologista após palpitações sem causa orgânica.","pastMedicalHistory":"Apendicectomia aos 15 anos. Avaliação cardiológica recente: Holter normal.","familyHistory":"Pai faleceu de IAM aos 65 anos. Mãe hipertensa. Tia materna com depressão.","personalHistory":{"previousDiseases":"Palpitações em investigação - ECG e Holter normais","surgeries":"Apendicectomia (2012)","hospitalizations":"Nenhuma psiquiátrica","allergies":"Dipirona - urticária","currentMedications":"Nenhum psicotrópico","vaccinations":"Esquema vacinal completo"},"lifestyle":{"diet":"Irregular, reduziu café recentemente","physicalActivity":"Sedentário, iniciando caminhadas","smoking":"Nunca fumou","alcohol":"Social, fins de semana","drugs":"Nega","sleep":"Insônia inicial há 2 meses, dorme 5-6h"}}'
WHERE Id = '7F5E0A3E-7D24-440C-BE35-1A6983C25B89';

-- 17/01/2026 - Seguimento cardiológico
UPDATE Appointments SET AnamnesisJson = '{"chiefComplaint":"Seguimento de palpitações - melhora significativa","presentIllnessHistory":"Retorno de rotina. Refere melhora importante após mudanças no estilo de vida. Palpitações raras. Em acompanhamento psiquiátrico para TAG.","pastMedicalHistory":"Apendicectomia aos 15 anos. TAG diagnosticado recentemente.","familyHistory":"Pai faleceu de IAM aos 65 anos. Mãe hipertensa em tratamento. Tia materna com depressão.","personalHistory":{"previousDiseases":"TAG em tratamento","surgeries":"Apendicectomia (2012)","hospitalizations":"Nenhuma","allergies":"Dipirona - urticária","currentMedications":"Escitalopram 10mg/dia (psiquiatria)","vaccinations":"Esquema vacinal completo"},"lifestyle":{"diet":"Melhorou, reduziu café","physicalActivity":"Caminhadas 3x/semana","smoking":"Nunca fumou","alcohol":"Social moderado","drugs":"Nega","sleep":"Regular, 7h/noite"}}'
WHERE Id = '42DF3E58-7995-424D-A85A-16EEB450CD64';

-- 23/01/2026 - Seguimento TAG (psiquiatria)
UPDATE Appointments SET AnamnesisJson = '{"chiefComplaint":"Seguimento de Transtorno de Ansiedade Generalizada","presentIllnessHistory":"Retorno mensal. Em uso de Escitalopram 15mg há 6 semanas. Refere melhora da ansiedade e do sono. Palpitações cessaram.","pastMedicalHistory":"TAG diagnosticado há 6 semanas. Apendicectomia prévia.","familyHistory":"Pai faleceu de IAM aos 65 anos. Mãe hipertensa. Tia materna com depressão.","personalHistory":{"previousDiseases":"TAG em tratamento","surgeries":"Apendicectomia (2012)","hospitalizations":"Nenhuma psiquiátrica","allergies":"Dipirona - urticária","currentMedications":"Escitalopram 15mg pela manhã","vaccinations":"Esquema vacinal completo"},"lifestyle":{"diet":"Equilibrada, café moderado","physicalActivity":"Caminhadas 4x/semana, yoga 1x","smoking":"Nunca fumou","alcohol":"Reduziu para 1x/mês","drugs":"Nega","sleep":"Regular, 7-8h/noite, sem insônia"}}'
WHERE Id = '19191513-7611-4B00-99E0-0AB4A1B67BA5';

-- ============================================================
-- MARIA SILVA (F764F4E1-E999-4254-9272-FB1BAD994E59)
-- 62 anos, hipertensa, dislipidêmica
-- ============================================================

-- 06/01/2026 - Controle HAS
UPDATE Appointments SET AnamnesisJson = '{"chiefComplaint":"Controle de pressão arterial","presentIllnessHistory":"Hipertensa há 15 anos, em tratamento regular. Refere bom uso das medicações. PA domiciliar entre 135-140/85 mmHg.","pastMedicalHistory":"HAS há 15 anos. Dislipidemia. Colecistectomia em 2015. Menopausa aos 52 anos.","familyHistory":"Pai e mãe hipertensos. Pai teve AVC aos 70 anos. Mãe diabética tipo 2.","personalHistory":{"previousDiseases":"HAS, dislipidemia, menopausa","surgeries":"Colecistectomia laparoscópica (2015)","hospitalizations":"Apenas para cirurgia","allergies":"Penicilina - edema de glote","currentMedications":"Losartana 50mg 1x/dia, Anlodipino 5mg 1x/dia, Sinvastatina 20mg à noite","vaccinations":"COVID-19 e Influenza em dia"},"lifestyle":{"diet":"Dieta DASH, restrição de sal","physicalActivity":"Caminhadas 3x/semana, 30 minutos","smoking":"Nunca fumou","alcohol":"Abstêmia","drugs":"Nega","sleep":"Regular, 7h/noite"}}'
WHERE Id = 'ADC227DF-9C3B-498A-A92D-B1BB0DA3B91B';

-- 11/01/2026 - Insônia (psiquiatria)
UPDATE Appointments SET AnamnesisJson = '{"chiefComplaint":"Insônia crônica há 3 meses","presentIllnessHistory":"Encaminhada pelo cardiologista por insônia de manutenção. Acorda várias vezes à noite. Dificuldade para retomar o sono. Cansaço diurno.","pastMedicalHistory":"HAS há 15 anos. Dislipidemia. Colecistectomia em 2015. Menopausa aos 52 anos.","familyHistory":"Pai e mãe hipertensos. Pai teve AVC. Mãe diabética.","personalHistory":{"previousDiseases":"HAS, dislipidemia","surgeries":"Colecistectomia (2015)","hospitalizations":"Nenhuma psiquiátrica","allergies":"Penicilina - edema de glote","currentMedications":"Losartana 50mg, Anlodipino 5mg, Sinvastatina 20mg","vaccinations":"Em dia"},"lifestyle":{"diet":"DASH, restrição de sal","physicalActivity":"Caminhadas 3x/semana","smoking":"Nunca fumou","alcohol":"Abstêmia","drugs":"Nega","sleep":"Insônia de manutenção há 3 meses, dorme 4-5h fragmentadas"}}'
WHERE Id = '561F08B5-6DCD-47E4-BCA4-1F93FED65A9B';

-- 13/01/2026 - Reavaliação HAS
UPDATE Appointments SET AnamnesisJson = '{"chiefComplaint":"Reavaliação de hipertensão - ajuste medicação","presentIllnessHistory":"Retorno após aumento de Anlodipino. PA domiciliar estável 125-130/78-82 mmHg. Sem edema de tornozelos. Sono melhorando com tratamento psiquiátrico.","pastMedicalHistory":"HAS há 15 anos. Dislipidemia. Insônia em tratamento.","familyHistory":"Pai e mãe hipertensos. Pai teve AVC aos 70 anos. Mãe diabética.","personalHistory":{"previousDiseases":"HAS, dislipidemia, insônia","surgeries":"Colecistectomia (2015)","hospitalizations":"Nenhuma recente","allergies":"Penicilina - edema de glote","currentMedications":"Losartana 50mg, Anlodipino 10mg, Sinvastatina 20mg, Zolpidem 5mg se necessário","vaccinations":"Em dia"},"lifestyle":{"diet":"DASH, boa adesão","physicalActivity":"Caminhadas 4x/semana","smoking":"Nunca fumou","alcohol":"Abstêmia","drugs":"Nega","sleep":"Melhorando, 6h/noite com medicação"}}'
WHERE Id = 'E705B3BA-0E09-4D10-9BFA-94DFCFE1EAF1';

-- 18/01/2026 - Controle PA mensal
UPDATE Appointments SET AnamnesisJson = '{"chiefComplaint":"Controle mensal de pressão arterial","presentIllnessHistory":"Acompanhamento mensal de HAS. PA domiciliar estável em meta (<130/80). Sem queixas cardiovasculares. Tolerando bem medicações.","pastMedicalHistory":"HAS há 15 anos, bom controle atual. Dislipidemia. Insônia tratada.","familyHistory":"Pai e mãe hipertensos. Pai AVC. Mãe DM2.","personalHistory":{"previousDiseases":"HAS, dislipidemia","surgeries":"Colecistectomia (2015)","hospitalizations":"Nenhuma","allergies":"Penicilina - edema de glote","currentMedications":"Losartana 50mg, Anlodipino 10mg, Sinvastatina 20mg","vaccinations":"Em dia"},"lifestyle":{"diet":"DASH, disciplinada","physicalActivity":"Caminhadas 4x/semana, hidroginástica 2x","smoking":"Nunca","alcohol":"Abstêmia","drugs":"Nega","sleep":"Regular, 7h/noite"}}'
WHERE Id = '1D5C535A-902B-4A41-A754-2830510D1160';

-- ============================================================
-- JOÃO SANTOS (AE637012-D984-4583-8824-3EABB5911886)
-- 38 anos, transtorno do pânico
-- ============================================================

-- 07/01/2026 - Primeira consulta pânico janeiro
UPDATE Appointments SET AnamnesisJson = '{"chiefComplaint":"Crises de ansiedade intensas com medo de morrer","presentIllnessHistory":"Crises de pânico há 3 meses. Taquicardia, sudorese, tremores, dispneia, medo intenso de morte. Episódios duram 15-30 min, 2-3x/semana. Evitação de locais fechados. Em tratamento desde dezembro.","pastMedicalHistory":"Hígido. Uso pregresso de maconha na adolescência, abstinente há 5 anos.","familyHistory":"Tia materna com síndrome do pânico. Avó com depressão.","personalHistory":{"previousDiseases":"Transtorno do Pânico diagnosticado em dezembro/2025","surgeries":"Nenhuma","hospitalizations":"2 idas ao PS por crises de pânico - exames cardíacos normais","allergies":"Nega","currentMedications":"Sertralina 50mg, Clonazepam 0.5mg SOS","vaccinations":"Em dia"},"lifestyle":{"diet":"Regular","physicalActivity":"Parou academia por medo de crises","smoking":"Nunca","alcohol":"Reduziu por medo de gatilhos","drugs":"Maconha no passado, abstinente há 5 anos","sleep":"Insônia inicial, 5h/noite"}}'
WHERE Id = '028DBAD0-2E50-430A-A1A3-8D20C6BF1F28';

-- 14/01/2026 - Retorno pânico (melhora)
UPDATE Appointments SET AnamnesisJson = '{"chiefComplaint":"Retorno - melhora significativa do pânico","presentIllnessHistory":"Retorno após 2 semanas de Sertralina 50mg. Apenas 1 crise leve na semana. Não precisou usar Clonazepam. Conseguiu usar metrô acompanhado. Voltou ao trabalho.","pastMedicalHistory":"Transtorno do Pânico com Agorafobia em tratamento desde dezembro/2025.","familyHistory":"Tia materna com síndrome do pânico. Avó com depressão.","personalHistory":{"previousDiseases":"Transtorno do Pânico com Agorafobia","surgeries":"Nenhuma","hospitalizations":"2 idas ao PS em 2025 por pânico","allergies":"Nega","currentMedications":"Sertralina 50mg pela manhã","vaccinations":"Em dia"},"lifestyle":{"diet":"Regular, melhorou apetite","physicalActivity":"Retomando gradualmente","smoking":"Nunca","alcohol":"Abstinente","drugs":"Abstinente há 5 anos","sleep":"Melhorou, 7h/noite"}}'
WHERE Id = 'C9FB6D4A-531E-43E9-A423-5931F93E3FFD';

-- 15/01/2026 - Liberação academia (cardio)
UPDATE Appointments SET AnamnesisJson = '{"chiefComplaint":"Liberação cardiológica para atividade física","presentIllnessHistory":"Solicita avaliação para liberação de academia. Histórico de pânico com palpitações. Exames cardíacos normais. Em tratamento psiquiátrico com boa resposta.","pastMedicalHistory":"Transtorno do Pânico com Agorafobia em tratamento. Exames cardiológicos prévios normais.","familyHistory":"Tia materna com pânico. Avó com depressão. Sem cardiopatias.","personalHistory":{"previousDiseases":"Transtorno do Pânico em remissão","surgeries":"Nenhuma","hospitalizations":"2 PS por pânico (2025)","allergies":"Nega","currentMedications":"Sertralina 100mg pela manhã","vaccinations":"Em dia"},"lifestyle":{"diet":"Regular","physicalActivity":"Deseja retomar academia","smoking":"Nunca","alcohol":"Abstinente","drugs":"Abstinente há 5 anos","sleep":"Regular, 7h/noite"}}'
WHERE Id = '5D5ECF04-41D0-4613-8FF4-54343D54E654';

-- 19/01/2026 - Manutenção ansiedade
UPDATE Appointments SET AnamnesisJson = '{"chiefComplaint":"Seguimento de Transtorno do Pânico - em remissão","presentIllnessHistory":"Manutenção mensal. Sem crises de pânico há 3 semanas. Consegue usar transporte público sozinho. Voltou à academia. Vida normalizada.","pastMedicalHistory":"Transtorno do Pânico com Agorafobia - em remissão com Sertralina.","familyHistory":"Tia materna com pânico. Avó com depressão.","personalHistory":{"previousDiseases":"Transtorno do Pânico (remissão)","surgeries":"Nenhuma","hospitalizations":"2 PS por pânico em 2025","allergies":"Nega","currentMedications":"Sertralina 100mg pela manhã","vaccinations":"Em dia"},"lifestyle":{"diet":"Saudável","physicalActivity":"Academia 4x/semana, liberado pelo cardiologista","smoking":"Nunca","alcohol":"Social ocasional","drugs":"Abstinente há 5 anos","sleep":"Excelente, 7-8h/noite"}}'
WHERE Id = '7F9989B8-B5D9-491D-ADF1-7EB3ED904FF2';

-- ============================================================
-- ANA OLIVEIRA (BA040C1B-869F-4307-AA80-C6EFC83D95D1)
-- 32 anos, gestante
-- ============================================================

-- 08/01/2026 - Avaliação cardio gestacional
UPDATE Appointments SET AnamnesisJson = '{"chiefComplaint":"Avaliação de sopro cardíaco na gestação","presentIllnessHistory":"Gestante G1P0A0, 20 semanas, retorna com ecocardiograma. Sopro detectado no pré-natal. Assintomática cardiovascularmente.","pastMedicalHistory":"Hígida. G1P0A0. Pré-natal sem intercorrências. US morfológico normal.","familyHistory":"Sem cardiopatias. Mãe teve pré-eclâmpsia na primeira gestação.","personalHistory":{"previousDiseases":"Nenhuma","surgeries":"Nenhuma","hospitalizations":"Nenhuma","allergies":"Nega","currentMedications":"Ácido fólico 5mg, Sulfato ferroso 40mg, Polivitamínico","vaccinations":"Vacinas gestacionais em dia"},"lifestyle":{"diet":"Balanceada, acompanhada por nutricionista","physicalActivity":"Yoga 2x/semana, caminhadas leves","smoking":"Nunca fumou","alcohol":"Abstêmia desde início da gestação","drugs":"Nega","sleep":"Regular, 8h/noite, noctúria 1x"}}'
WHERE Id = 'CECCDB6C-CC87-439B-8238-1883FBABC740';

-- 18/01/2026 - Ansiedade gestacional (psiq)
UPDATE Appointments SET AnamnesisJson = '{"chiefComplaint":"Ansiedade na gestação - primeira gravidez","presentIllnessHistory":"Gestante 22 semanas, encaminhada pelo obstetra. Preocupação excessiva com saúde do bebê, medo do parto. Pesquisas excessivas na internet. Sono inquieto.","pastMedicalHistory":"Hígida. G1P0A0. Pré-natal normal. Ecocardiograma normal (sopro funcional).","familyHistory":"Mãe com pré-eclâmpsia. Sem histórico psiquiátrico familiar.","personalHistory":{"previousDiseases":"Nenhuma","surgeries":"Nenhuma","hospitalizations":"Nenhuma","allergies":"Nega","currentMedications":"Ácido fólico 5mg, Sulfato ferroso 40mg, Polivitamínico","vaccinations":"Gestacionais em dia"},"lifestyle":{"diet":"Balanceada","physicalActivity":"Yoga gestacional 2x/semana","smoking":"Nunca","alcohol":"Abstêmia","drugs":"Nega","sleep":"Inquieto, dificuldade para relaxar, 6-7h/noite"}}'
WHERE Id = '6ECACC73-9EC2-4B76-8948-3AC89714BC2C';

-- 20/01/2026 - Seguimento gestação (cardio)
UPDATE Appointments SET AnamnesisJson = '{"chiefComplaint":"Seguimento cardiológico gestacional - 24 semanas","presentIllnessHistory":"Retorno opcional a pedido da paciente para tranquilização. 24 semanas, assintomática. Pré-natal sem intercorrências.","pastMedicalHistory":"Hígida. G1P0A0. Eco normal - sopro funcional. Ansiedade gestacional leve.","familyHistory":"Mãe com pré-eclâmpsia.","personalHistory":{"previousDiseases":"Ansiedade gestacional leve","surgeries":"Nenhuma","hospitalizations":"Nenhuma","allergies":"Nega","currentMedications":"Ácido fólico, Sulfato ferroso, Polivitamínico","vaccinations":"Gestacionais em dia"},"lifestyle":{"diet":"Balanceada","physicalActivity":"Yoga, caminhadas","smoking":"Nunca","alcohol":"Abstêmia","drugs":"Nega","sleep":"Melhor após suporte psicológico"}}'
WHERE Id = '3C8FAB75-8E28-4FF8-9F0C-DB5D74D2358D';

-- ============================================================
-- PEDRO COSTA (E7657BF8-9F97-4EF3-9FF3-48B02C2F8A52)
-- 55 anos, diabético
-- ============================================================

-- 09/01/2026 - Avaliação cardiovascular DM
UPDATE Appointments SET AnamnesisJson = '{"chiefComplaint":"Avaliação cardiovascular - diabético","presentIllnessHistory":"DM2 há 10 anos, encaminhado para estratificação. Último HbA1c 7.2%. Retorna com ECG e Eco solicitados em dezembro.","pastMedicalHistory":"DM2 há 10 anos. Dislipidemia. Retinopatia diabética não proliferativa leve. Neuropatia sensitiva em pés. Ex-tabagista.","familyHistory":"Pai DM2, faleceu de AVC aos 68 anos. Mãe HAS. Irmã DM2.","personalHistory":{"previousDiseases":"DM2, dislipidemia, retinopatia leve, neuropatia","surgeries":"Nenhuma","hospitalizations":"Nenhuma cardiovascular","allergies":"Nega","currentMedications":"Metformina 850mg 2x/dia, Glibenclamida 5mg, AAS 100mg, Atorvastatina 20mg","vaccinations":"Em dia, incluindo pneumocócica"},"lifestyle":{"diet":"Dificuldade com restrição de carboidratos","physicalActivity":"Sedentário, iniciando caminhadas","smoking":"Ex-tabagista há 5 anos (20 maços-ano)","alcohol":"Social ocasional","drugs":"Nega","sleep":"Regular, 7h/noite"}}'
WHERE Id = '3AE49CF2-3991-4CEA-B82F-6999873D244B';

-- 16/01/2026 - Retorno com exames
UPDATE Appointments SET AnamnesisJson = '{"chiefComplaint":"Retorno com exames cardiológicos - estratificação","presentIllnessHistory":"Retorno pós-ajuste. Tolerando bem Enalapril. Sem tosse. PA domiciliar melhor. Caminhando 3x/semana.","pastMedicalHistory":"DM2 há 10 anos. HAS. Dislipidemia. Doença aterosclerótica subclínica (placas carotídeas). Neuropatia diabética.","familyHistory":"Pai DM2 + AVC. Mãe HAS. Irmã DM2.","personalHistory":{"previousDiseases":"DM2, HAS, dislipidemia, aterosclerose subclínica","surgeries":"Nenhuma","hospitalizations":"Nenhuma","allergies":"Nega","currentMedications":"Metformina 850mg 2x, Glibenclamida 5mg, AAS 100mg, Atorvastatina 40mg, Enalapril 10mg","vaccinations":"Em dia"},"lifestyle":{"diet":"Melhorando adesão à dieta","physicalActivity":"Caminhadas 3x/semana, 30min","smoking":"Ex-tabagista há 5 anos","alcohol":"Reduziu","drugs":"Nega","sleep":"Regular"}}'
WHERE Id = '9EF50898-1B84-4B3A-92A4-4D98ADA8FBB0';

-- 19/01/2026 - Rastreio depressão (psiq)
UPDATE Appointments SET AnamnesisJson = '{"chiefComplaint":"Rastreio de depressão - rotina em diabéticos","presentIllnessHistory":"Encaminhado para rastreio de depressão conforme protocolo de DM. Nega humor deprimido. Refere frustração com restrições dietéticas. Sono e energia normais.","pastMedicalHistory":"DM2 há 10 anos. HAS. Dislipidemia. Aterosclerose subclínica.","familyHistory":"Pai DM2 + AVC. Mãe HAS. Sem histórico psiquiátrico familiar.","personalHistory":{"previousDiseases":"DM2, HAS, dislipidemia","surgeries":"Nenhuma","hospitalizations":"Nenhuma","allergies":"Nega","currentMedications":"Metformina 850mg 2x, Glibenclamida 5mg, AAS 100mg, Atorvastatina 40mg, Enalapril 10mg, Ezetimiba 10mg","vaccinations":"Em dia"},"lifestyle":{"diet":"Em adaptação, acompanha nutricionista","physicalActivity":"Caminhadas regulares","smoking":"Ex-tabagista há 5 anos","alcohol":"Ocasional","drugs":"Nega","sleep":"Regular, 7h"}}'
WHERE Id = 'CC3F489F-4531-4A0C-98D4-28D058C0E3FF';

-- 21/01/2026 - Controle DM/HAS
UPDATE Appointments SET AnamnesisJson = '{"chiefComplaint":"Controle trimestral DM e HAS","presentIllnessHistory":"Controle de rotina. PA domiciliar 120-128/78-82. Glicemias de jejum 110-130. LDL em meta. Caminhando regularmente.","pastMedicalHistory":"DM2 há 10 anos, bom controle. HAS controlada. Dislipidemia em meta. Aterosclerose subclínica estável.","familyHistory":"Pai DM2 + AVC. Mãe HAS. Irmã DM2.","personalHistory":{"previousDiseases":"DM2, HAS, dislipidemia","surgeries":"Nenhuma","hospitalizations":"Nenhuma","allergies":"Nega","currentMedications":"Metformina 850mg 2x, Glibenclamida 5mg, AAS 100mg, Atorvastatina 40mg + Ezetimiba 10mg, Enalapril 10mg","vaccinations":"Em dia"},"lifestyle":{"diet":"DASH/diabético, boa adesão","physicalActivity":"Caminhadas 4x/semana, 40min","smoking":"Ex-tabagista há 5 anos","alcohol":"Ocasional","drugs":"Nega","sleep":"Regular, 7h"}}'
WHERE Id = '16E81A55-7410-4895-8B73-FAD28E8A1CF2';

-- ============================================================
-- LÚCIA FERREIRA (903F9074-FA7B-492E-A670-44C827B4CFDD)
-- 58 anos, depressão grave por luto
-- ============================================================

-- 08/01/2026 - Avaliação depressão grave
UPDATE Appointments SET AnamnesisJson = '{"chiefComplaint":"Tristeza profunda e desânimo há 8 meses","presentIllnessHistory":"Retorno em 7 dias. Primeira semana de Mirtazapina 15mg. Sono melhorou. Apetite retornando. Humor ainda muito triste. Filha acompanhando.","pastMedicalHistory":"Episódio depressivo leve há 20 anos, tratado 1 ano. HAS. Osteopenia. Viúva há 1 ano.","familyHistory":"Mãe com depressão grave, internação psiquiátrica. Irmã usa antidepressivo.","personalHistory":{"previousDiseases":"Episódio depressivo prévio (tratado), HAS, osteopenia","surgeries":"Histerectomia (2010)","hospitalizations":"Nenhuma psiquiátrica","allergies":"Sulfa - reação cutânea grave","currentMedications":"Losartana 50mg, Cálcio + Vit D, Mirtazapina 15mg","vaccinations":"Em dia"},"lifestyle":{"diet":"Inapetência, mas melhorando","physicalActivity":"Parou todas atividades","smoking":"Nunca","alcohol":"Nunca","drugs":"Nunca","sleep":"Melhorando com Mirtazapina, 6-7h"}}'
WHERE Id = 'CC218030-FFA3-4C16-A541-E3E531DADBB4';

-- 15/01/2026 - Retorno depressão
UPDATE Appointments SET AnamnesisJson = '{"chiefComplaint":"Retorno depressão - melhora progressiva","presentIllnessHistory":"Segunda semana de tratamento. Continua melhora. Dormindo bem. Voltou a comer com família. Chora menos. Visitou irmã. Iniciou psicoterapia.","pastMedicalHistory":"Depressão grave (F32.2) em tratamento. HAS. Osteopenia. Viúva há 1 ano.","familyHistory":"Mãe com depressão grave. Irmã usa antidepressivo.","personalHistory":{"previousDiseases":"Depressão grave atual, episódio prévio, HAS, osteopenia","surgeries":"Histerectomia (2010)","hospitalizations":"Nenhuma psiquiátrica","allergies":"Sulfa - reação cutânea grave","currentMedications":"Losartana 50mg, Cálcio + Vit D, Mirtazapina 30mg","vaccinations":"Em dia"},"lifestyle":{"diet":"Melhorando, comendo com família","physicalActivity":"Iniciou caminhadas leves","smoking":"Nunca","alcohol":"Nunca","drugs":"Nunca","sleep":"Regular, 7h com Mirtazapina"}}'
WHERE Id = 'E0A037C7-1D6C-4D31-AC20-F8DDB44BC0B6';

-- 20/01/2026 - Avaliação cardio palpitações
UPDATE Appointments SET AnamnesisJson = '{"chiefComplaint":"Palpitações ocasionais desde início do antidepressivo","presentIllnessHistory":"Encaminhada pelo psiquiatra. Em tratamento para depressão com Mirtazapina 30mg. Palpitações ocasionais, sem dor torácica. Evolução psiquiátrica boa.","pastMedicalHistory":"Depressão grave em tratamento. HAS. Osteopenia.","familyHistory":"Mãe com depressão grave. Pai HAS.","personalHistory":{"previousDiseases":"Depressão em tratamento, HAS, osteopenia","surgeries":"Histerectomia (2010)","hospitalizations":"Nenhuma","allergies":"Sulfa - reação cutânea grave","currentMedications":"Losartana 50mg, Cálcio + Vit D, Mirtazapina 30mg","vaccinations":"Em dia"},"lifestyle":{"diet":"Regular, apetite normal","physicalActivity":"Caminhadas 3x/semana","smoking":"Nunca","alcohol":"Nunca","drugs":"Nunca","sleep":"Regular, 7h"}}'
WHERE Id = 'FDF34B8F-EB30-49AE-A8D7-9E3DE132289B';

-- 22/01/2026 - Melhora depressão
UPDATE Appointments SET AnamnesisJson = '{"chiefComplaint":"Melhora significativa da depressão","presentIllnessHistory":"Quarta semana de tratamento. Humor muito melhor. Voltou a cuidar do jardim. Participa do grupo de oração. Sente saudades do marido mas consegue lembrar sem chorar tanto.","pastMedicalHistory":"Depressão grave em remissão parcial. HAS. Osteopenia.","familyHistory":"Mãe com depressão grave. Irmã usa antidepressivo.","personalHistory":{"previousDiseases":"Depressão (remissão parcial), HAS, osteopenia","surgeries":"Histerectomia (2010)","hospitalizations":"Nenhuma","allergies":"Sulfa - reação cutânea grave","currentMedications":"Losartana 50mg, Cálcio + Vit D, Mirtazapina 30mg","vaccinations":"Em dia"},"lifestyle":{"diet":"Normal, cozinha para a família novamente","physicalActivity":"Jardinagem, caminhadas, grupo de oração","smoking":"Nunca","alcohol":"Nunca","drugs":"Nunca","sleep":"Excelente, 7-8h"}}'
WHERE Id = 'E1194F79-CA05-479C-A381-32615CAB4C57';

-- ============================================================
-- FIM DO SCRIPT
-- ============================================================
