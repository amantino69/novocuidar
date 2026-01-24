-- ============================================================
-- SCRIPT PARA CORRIGIR FORMATO JSON PARA FRONTEND
-- POC TELECUIDAR - 24/01/2026
-- ============================================================
-- O frontend espera campos em inglês (camelCase)
-- O banco estava com campos em português
-- ============================================================

-- ============================================================
-- DANIEL CARRARA - CONSULTAS COM GERALDO (CARDIO)
-- ============================================================

-- 15/12/2025 - Check-up dezembro
UPDATE Appointments SET 
SoapJson = '{"subjective":"Paciente jovem, comparece para check-up de rotina. Refere episódios ocasionais de palpitações nos últimos 2 meses, geralmente após consumo excessivo de café. Nega dor torácica, dispneia ou síncope. Menciona estresse no trabalho e sono irregular (5-6 horas por noite).","objective":"Bom estado geral, corado, hidratado, eupneico, afebril. PA: 122/78 mmHg, FC: 72 bpm regular, FR: 16 irpm, SatO2: 98%. ACV: Bulhas rítmicas, normofonéticas, 2T, sem sopros. AR: MV presente bilateralmente, sem RA. Abdome: plano, RHA+, indolor. MMII: sem edema, pulsos presentes.","assessment":"Palpitações ocasionais a investigar - provável relação com consumo excessivo de cafeína e estresse. Paciente jovem, baixo risco cardiovascular.","plan":"1. Solicitar ECG de repouso\\n2. Orientar redução de cafeína (máx 2 xícaras/dia)\\n3. Higiene do sono\\n4. Retorno em 30 dias com exames"}',
AnamnesisJson = '{"chiefComplaint":"Check-up de rotina com queixa de palpitações ocasionais","presentIllnessHistory":"Palpitações há 2 meses, associadas a consumo de café e momentos de estresse. Episódios duram 5-15 minutos. Sem fatores de piora definidos. Nega síncope, dor precordial ou dispneia.","pastMedicalHistory":"Apendicectomia aos 15 anos. Nega internações clínicas.","familyHistory":"Pai faleceu de IAM aos 65 anos. Mãe hipertensa em tratamento. Irmão hígido.","personalHistory":{"previousDiseases":"Nega comorbidades","surgeries":"Apendicectomia (2012)","hospitalizations":"Apenas para cirurgia acima","allergies":"Dipirona - urticária","currentMedications":"Nenhum uso contínuo","vaccinations":"Esquema vacinal completo"},"lifestyle":{"diet":"Irregular, alto consumo de café","physicalActivity":"Sedentário","smoking":"Nunca fumou","alcohol":"Social, fins de semana","drugs":"Nega","sleep":"Irregular, 5-6h/noite"}}'
WHERE Id = '9BA1FF25-71CE-44BE-A18F-71ECA2E39282';

-- 05/01/2026 - Consulta cardiológica (palpitações)
UPDATE Appointments SET 
SoapJson = '{"subjective":"Retorna com queixa de palpitações mais frequentes nas últimas semanas. Refere episódios 2-3x por semana, principalmente à noite. Reduziu café mas mantém estresse no trabalho. Nega dor torácica, síncope ou dispneia.","objective":"REG, corado, hidratado. PA: 130/85 mmHg, FC: 88 bpm regular, FR: 18 irpm. ACV: BRNF 2T, sem sopros. Pulsos periféricos simétricos. ECG de repouso: ritmo sinusal, FC 85 bpm, sem alterações de repolarização.","assessment":"Palpitações frequentes - solicitar Holter 24h para melhor caracterização. ECG de repouso normal. Possível componente ansioso associado.","plan":"1. Solicitar Holter 24h\\n2. Solicitar exames laboratoriais (TSH, hemograma)\\n3. Manter orientações de redução de cafeína\\n4. Considerar avaliação psiquiátrica se persistir\\n5. Retorno em 7 dias com Holter"}'
WHERE Id = '7815A758-5E15-4B86-B0CB-2A5AF007F643';

-- 10/01/2026 - Retorno cardiológico com exames
UPDATE Appointments SET 
SoapJson = '{"subjective":"Retorna para avaliação de Holter 24h. Refere melhora das palpitações após redução do café. Dormindo melhor. Mantém episódios esporádicos mas menos intensos.","objective":"BEG, corado, hidratado. PA: 125/80 mmHg, FC: 72 bpm regular. ACV: BRNF 2T, sem sopros. Holter 24h: ritmo sinusal predominante, FC média 74 bpm, extrassístoles supraventriculares isoladas (<1% do total), sem pausas significativas.","assessment":"Holter 24h demonstrando extrassístoles supraventriculares isoladas, sem significado patológico. Correlação com sintomas: palpitações correspondem a ESV isoladas. Quadro benigno.","plan":"1. Tranquilizar paciente sobre benignidade do quadro\\n2. Manter redução de cafeína\\n3. Atividade física regular\\n4. Considerar avaliação para TAG\\n5. Retorno em 30 dias"}'
WHERE Id = '2FCA8FFE-EC90-4BA3-A4F9-AF28D64D9220';

-- 17/01/2026 - Seguimento cardiológico
UPDATE Appointments SET 
SoapJson = '{"subjective":"Seguimento de palpitações. Paciente refere melhora significativa após mudanças no estilo de vida. Iniciou caminhadas 3x/semana. Reduziu café para 1 xícara/dia. Dormindo 7h/noite. Episódios de palpitação raros e menos intensos.","objective":"BEG, corado, hidratado, tranquilo. PA: 120/78 mmHg, FC: 68 bpm regular. ACV: BRNF 2T, sem sopros. Sem sinais de ansiedade manifesta.","assessment":"Melhora clínica significativa com mudanças de estilo de vida. Extrassístoles supraventriculares benignas em regressão. Possível componente ansioso controlado.","plan":"1. Manter atividade física\\n2. Manter restrição de cafeína\\n3. Alta do acompanhamento cardiológico\\n4. Retorno PRN"}'
WHERE Id = '42DF3E58-7995-424D-A85A-16EEB450CD64';

-- ============================================================
-- DANIEL CARRARA - CONSULTAS COM ANTÔNIO (PSIQ)
-- ============================================================

-- 12/01/2026 - Consulta psiquiátrica (ansiedade)
UPDATE Appointments SET 
SoapJson = '{"subjective":"Encaminhado pelo cardiologista para avaliação de possível transtorno de ansiedade. Refere preocupação excessiva há 6 meses, dificuldade para relaxar, tensão muscular e irritabilidade. Associa palpitações aos momentos de maior ansiedade. Sono não reparador, acorda cansado.","objective":"Lúcido, orientado, cooperativo. Humor ansioso, afeto congruente. Fala em ritmo acelerado. Mãos sudoreicas. Sem alterações do pensamento ou sensopercepção. Sem ideação suicida. GAD-7: 14 (ansiedade moderada). PHQ-9: 8 (depressão leve).","assessment":"Transtorno de Ansiedade Generalizada (F41.1) - gravidade moderada. Sintomas cardiovasculares (palpitações) secundários ao quadro ansioso.","plan":"1. Iniciar Escitalopram 10mg pela manhã\\n2. Psicoeducação sobre TAG\\n3. Orientar técnicas de respiração e relaxamento\\n4. Encaminhar para psicoterapia TCC\\n5. Retorno em 15 dias para avaliação de resposta"}'
WHERE Id = '7F5E0A3E-7D24-440C-BE35-1A6983C25B89';

-- 23/01/2026 - Seguimento TAG
UPDATE Appointments SET 
SoapJson = '{"subjective":"Retorno para avaliação de resposta ao Escitalopram. Refere discreta melhora da ansiedade na segunda semana. Efeitos colaterais iniciais (náusea leve) já resolvidos. Palpitações menos frequentes. Sono melhorando. Iniciou psicoterapia TCC.","objective":"Lúcido, orientado, menos ansioso. Humor eutímico. Afeto modulado. Fala em ritmo normal. Sem tremores. GAD-7: 10 (melhora de 4 pontos). PHQ-9: 5 (melhora).","assessment":"Transtorno de Ansiedade Generalizada em tratamento - resposta parcial inicial ao Escitalopram. Evolução favorável.","plan":"1. Aumentar Escitalopram para 15mg pela manhã\\n2. Manter psicoterapia TCC\\n3. Reforçar técnicas de manejo de ansiedade\\n4. Retorno em 30 dias"}'
WHERE Id = '19191513-7611-4B00-99E0-0AB4A1B67BA5';

-- ============================================================
-- MARIA SILVA - CONSULTAS (HIPERTENSA)
-- ============================================================

-- 18/12/2025 - Ajuste HAS
UPDATE Appointments SET 
SoapJson = '{"subjective":"Paciente hipertensa em acompanhamento. Refere bom uso das medicações. Aferições domiciliares entre 140-150/90 mmHg. Nega cefaleia, tontura ou alterações visuais. Mantém dieta com restrição de sal e caminhadas 3x/semana.","objective":"BEG, corada, hidratada. PA: 145/92 mmHg (MSD sentada), FC: 78 bpm. IMC: 28.8 kg/m². ACV: BRNF, B4 presente, sem sopros. MMII: sem edema, pulsos presentes.","assessment":"Hipertensão Arterial Sistêmica estágio 1, controle subótimo com terapia dupla atual. Sobrepeso.","plan":"1. Aumentar Anlodipino de 5mg para 10mg\\n2. Manter Losartana 50mg\\n3. Reforçar dieta DASH\\n4. Solicitar exames: função renal, potássio, perfil lipídico\\n5. Retorno em 30 dias"}',
AnamnesisJson = '{"chiefComplaint":"Controle de hipertensão arterial","presentIllnessHistory":"HAS há 15 anos, em tratamento regular. Últimas aferições domiciliares elevadas (140-150/90). Boa adesão medicamentosa. Sem sintomas de lesão de órgão-alvo.","pastMedicalHistory":"HAS há 15 anos. Dislipidemia. Menopausa aos 52 anos.","familyHistory":"Pai e mãe hipertensos. Pai teve AVC aos 70 anos. Mãe DM2.","personalHistory":{"previousDiseases":"HAS, dislipidemia","surgeries":"Colecistectomia (2015)","hospitalizations":"Nenhuma recente","allergies":"Penicilina - edema de glote","currentMedications":"Losartana 50mg 1x/dia, Anlodipino 5mg 1x/dia, Sinvastatina 20mg à noite","vaccinations":"COVID-19 e Influenza em dia"},"lifestyle":{"diet":"Restrição de sal, DASH","physicalActivity":"Caminhadas 3x/semana, 30min","smoking":"Nunca fumou","alcohol":"Abstêmia","drugs":"Nega","sleep":"Regular, 7h/noite"}}'
WHERE Id = '9A876D14-92B1-4943-92B7-C0C08A01D923';

-- 06/01/2026 - Controle HAS
UPDATE Appointments SET 
SoapJson = '{"subjective":"Retorno para controle de HAS. Refere melhora dos níveis pressóricos após ajuste medicamentoso. Aferições domiciliares entre 130-135/80-85 mmHg. Sem queixas. Tolerando bem Anlodipino 10mg, sem edema de tornozelos.","objective":"BEG, corada, hidratada. PA: 135/85 mmHg, FC: 68 bpm. Peso: 71.8kg. MMII: sem edema. Exames: Cr 0.9, K 4.2, Colesterol total 195, LDL 110, HDL 55, TG 150.","assessment":"HAS em melhor controle após otimização terapêutica. Dislipidemia controlada. Meta pressórica ainda não atingida (alvo <130/80 para paciente com DCV).","plan":"1. Manter medicações atuais\\n2. Intensificar MEV\\n3. Considerar adicionar diurético se PA não atingir meta\\n4. Retorno em 30 dias"}'
WHERE Id = 'ADC227DF-9C3B-498A-A92D-B1BB0DA3B91B';

-- 13/01/2026 - Reavaliação HAS
UPDATE Appointments SET 
SoapJson = '{"subjective":"Controle pressórico. Aferições domiciliares estáveis entre 125-130/78-82 mmHg. Aumentou atividade física para 4x/semana. Perdeu 500g. Sem queixas cardiovasculares.","objective":"BEG, corada. PA: 125/78 mmHg, FC: 70 bpm. Peso: 71.5kg (-300g). Sem alterações ao exame.","assessment":"HAS controlada, atingindo meta pressórica. Boa resposta às mudanças de estilo de vida.","plan":"1. Manter esquema terapêutico atual\\n2. Continuar MEV\\n3. Retorno em 60 dias para manutenção"}'
WHERE Id = 'E705B3BA-0E09-4D10-9BFA-94DFCFE1EAF1';

-- 18/01/2026 - Controle mensal
UPDATE Appointments SET 
SoapJson = '{"subjective":"Manutenção de HAS controlada. PA domiciliar estável. Mantendo atividade física regular. Sem intercorrências.","objective":"BEG. PA: 128/82 mmHg, FC: 68 bpm. Peso: 71.2kg. Exame cardiovascular sem alterações.","assessment":"HAS estágio 1 controlada com terapia dupla. Paciente em meta terapêutica.","plan":"1. Manter Losartana 50mg + Anlodipino 10mg\\n2. Manter Sinvastatina 20mg\\n3. Próxima consulta em 3 meses\\n4. Repetir exames laboratoriais na próxima consulta"}'
WHERE Id = '1D5C535A-902B-4A41-A754-2830510D1160';

-- ============================================================
-- JOÃO SANTOS - CONSULTAS (PÂNICO)
-- ============================================================

-- 20/12/2025 - Início tratamento pânico
UPDATE Appointments SET 
SoapJson = '{"subjective":"Primeira consulta. Paciente refere crises súbitas de medo intenso há 3 meses. Descreve taquicardia, sudorese, tremores, falta de ar e sensação de morte iminente. Crises duram 15-30 minutos. Frequência 2-3x/semana. Desenvolveu medo de sair de casa e de usar transporte público.","objective":"Lúcido, orientado, ansioso. Hipervigilante. FC 98 bpm, mãos frias e sudoreicas. Humor ansioso, afeto congruente. Sem alterações de pensamento. Nega ideação suicida. PHQ-9: 12. GAD-7: 18.","assessment":"Transtorno de Pânico (F41.0) com Agorafobia (F40.0). Gravidade moderada a grave. Impacto funcional significativo.","plan":"1. Iniciar Sertralina 25mg (aumentar para 50mg em 7 dias)\\n2. Clonazepam 0.5mg SOS (máx 2x/dia por 4 semanas)\\n3. Psicoeducação sobre pânico\\n4. Encaminhar TCC urgente\\n5. Retorno em 15 dias"}',
AnamnesisJson = '{"chiefComplaint":"Crises de ansiedade intensa com medo de morrer","presentIllnessHistory":"Há 3 meses, iniciou com crises súbitas de taquicardia, sudorese, tremores, dispneia e medo intenso de morte. Episódios duram 15-30 min, ocorrem 2-3x/semana. Procurou PS 2x achando que era infarto - exames cardíacos normais. Desenvolveu evitação de locais fechados e transporte público.","pastMedicalHistory":"Hígido. Uso pregresso de maconha na adolescência.","familyHistory":"Tia materna com síndrome do pânico. Avó com depressão.","personalHistory":{"previousDiseases":"Nenhuma","surgeries":"Nenhuma","hospitalizations":"2 idas ao PS por pânico","allergies":"Nega","currentMedications":"Nenhum","vaccinations":"Em dia"},"lifestyle":{"diet":"Regular","physicalActivity":"Sedentário - parou academia por medo de crises","smoking":"Nunca","alcohol":"Social, reduziu por medo de gatilhos","drugs":"Maconha no passado, abstinente há 5 anos","sleep":"Insônia inicial há 2 meses, dorme 5h/noite"}}'
WHERE Id = '0FBB3E67-D948-478F-99BB-4B42D1F86102';

-- 07/01/2026 - Primeira consulta pânico janeiro
UPDATE Appointments SET 
SoapJson = '{"subjective":"Primeira semana de Sertralina 50mg. Refere náusea leve nos primeiros dias, já resolvida. Usou Clonazepam 2x. Crises de pânico menos intensas mas ainda presentes. Conseguiu ir ao supermercado acompanhado.","objective":"Menos ansioso que consulta anterior. FC 76 bpm. Mãos secas. Humor ansioso, mas menos que antes. PHQ-9: 10. GAD-7: 15.","assessment":"Transtorno de Pânico em tratamento inicial. Tolerância adequada à Sertralina. Resposta parcial esperada para o tempo de uso.","plan":"1. Manter Sertralina 50mg\\n2. Reduzir Clonazepam: usar apenas em crises intensas\\n3. Iniciar exposição gradual\\n4. Retorno em 7 dias"}'
WHERE Id = '028DBAD0-2E50-430A-A1A3-8D20C6BF1F28';

-- 14/01/2026 - Retorno pânico (melhora)
UPDATE Appointments SET 
SoapJson = '{"subjective":"Segunda semana de tratamento. Melhora significativa. Apenas 1 crise leve na semana. Não precisou usar Clonazepam. Conseguiu usar metrô acompanhado. Voltou ao trabalho presencial. Dormindo melhor.","objective":"Tranquilo, bom contato. FC 68 bpm. Sem sinais de ansiedade aguda. Humor eutímico. PHQ-9: 6. GAD-7: 10.","assessment":"Transtorno de Pânico com boa resposta à Sertralina. Melhora progressiva esperada. Iniciou enfrentamento da agorafobia.","plan":"1. Aumentar Sertralina para 100mg\\n2. Suspender Clonazepam\\n3. Continuar exposição gradual\\n4. Manter TCC\\n5. Retorno em 15 dias"}'
WHERE Id = 'C9FB6D4A-531E-43E9-A423-5931F93E3FFD';

-- 15/01/2026 - Liberação academia (cardio)
UPDATE Appointments SET 
SoapJson = '{"subjective":"Solicita avaliação cardiológica para liberação de atividade física em academia. Histórico de crises de pânico com palpitações. Exames prévios normais no PS. Em tratamento psiquiátrico com boa resposta.","objective":"BEG, corado, eupneico. PA: 118/72 mmHg, FC: 68 bpm regular. ACV: BRNF 2T, sem sopros. ECG: ritmo sinusal, sem alterações. Ausculta pulmonar normal.","assessment":"Paciente com Transtorno de Pânico em tratamento, sem evidência de cardiopatia estrutural. Apto para atividade física aeróbica moderada.","plan":"1. Liberado para academia: exercícios aeróbicos de intensidade leve a moderada\\n2. Iniciar gradualmente\\n3. Evitar exercícios de alta intensidade por enquanto\\n4. Orientar que FC alta no exercício é normal\\n5. Sem necessidade de retorno cardiológico"}'
WHERE Id = '5D5ECF04-41D0-4613-8FF4-54343D54E654';

-- 19/01/2026 - Manutenção ansiedade
UPDATE Appointments SET 
SoapJson = '{"subjective":"Excelente evolução. Sem crises de pânico há 10 dias. Consegue usar transporte público sozinho. Voltou à academia. Dormindo bem. Relacionamento melhorando.","objective":"Tranquilo, sorridente. Humor eutímico, afeto amplo. Sem sinais de ansiedade. PHQ-9: 3. GAD-7: 5.","assessment":"Transtorno de Pânico em remissão com Sertralina 100mg. Agorafobia superada.","plan":"1. Manter Sertralina 100mg por mínimo 12 meses\\n2. Manter TCC semanal por mais 2 meses, depois quinzenal\\n3. Retorno em 60 dias\\n4. Orientar sobre risco de recaída se suspensão precoce"}'
WHERE Id = '7F9989B8-B5D9-491D-ADF1-7EB3ED904FF2';

-- ============================================================
-- ANA OLIVEIRA - GESTANTE
-- ============================================================

-- 22/12/2025 - Primeira consulta gestante
UPDATE Appointments SET 
SoapJson = '{"subjective":"Gestante G1P0A0, 16 semanas, encaminhada pelo pré-natal para avaliação de sopro cardíaco detectado em consulta de rotina. Assintomática cardiovascularmente. Gestação desejada, bem acompanhada. Sem intercorrências obstétricas.","objective":"BEG, corada, hidratada. PA: 108/68 mmHg, FC: 88 bpm. Útero compatível com IG. BCF +. ACV: BRNF 2T, sopro sistólico +/6+ em BEE, irradia para axila.","assessment":"Gestante com sopro sistólico funcional (provavelmente por hiperfluxo gestacional). Baixa probabilidade de cardiopatia estrutural dado perfil clínico.","plan":"1. Solicitar Ecocardiograma para descartar valvopatia\\n2. Solicitar ECG\\n3. Tranquilizar paciente\\n4. Retorno com exames"}',
AnamnesisJson = '{"chiefComplaint":"Avaliação de sopro cardíaco detectado no pré-natal","presentIllnessHistory":"Sopro detectado em consulta de pré-natal às 16 semanas. Assintomática. Sem dispneia, palpitações, síncope ou edema. Gestação sem intercorrências.","pastMedicalHistory":"Hígida. G1P0A0. Pré-natal iniciado com 8 semanas. US morfológico normal.","familyHistory":"Sem cardiopatias. Mãe teve pré-eclâmpsia na primeira gestação.","personalHistory":{"previousDiseases":"Nenhuma","surgeries":"Nenhuma","hospitalizations":"Nenhuma","allergies":"Nega","currentMedications":"Ácido fólico 5mg, Sulfato ferroso 40mg, Polivitamínico","vaccinations":"Vacinas gestacionais em dia"},"lifestyle":{"diet":"Balanceada, orientada por nutricionista","physicalActivity":"Yoga 2x/semana","smoking":"Nunca","alcohol":"Abstêmia desde gestação","drugs":"Nega","sleep":"Regular"}}'
WHERE Id = 'C62C5612-05CC-437B-8A53-66A5D3C6A1F0';

-- 08/01/2026 - Avaliação cardio gestacional
UPDATE Appointments SET 
SoapJson = '{"subjective":"Retorna com ecocardiograma. Mantém-se assintomática. Gestação evoluindo bem, 20 semanas.","objective":"BEG. PA: 110/70 mmHg, FC: 82 bpm. BCF: 145 bpm. Eco: VE com dimensões normais, FE 68%, valvas normais, sem regurgitações patológicas. Sopro por hiperfluxo.","assessment":"Ecocardiograma normal. Sopro funcional gestacional confirmado. Sem cardiopatia estrutural.","plan":"1. Alta cardiológica\\n2. Seguimento normal no pré-natal\\n3. Retorno apenas se surgir sintoma cardiovascular\\n4. Parto pode ser vaginal sem restrições"}'
WHERE Id = 'CECCDB6C-CC87-439B-8238-1883FBABC740';

-- 18/01/2026 - Ansiedade gestacional (psiq)
UPDATE Appointments SET 
SoapJson = '{"subjective":"Encaminhada pelo obstetra por ansiedade gestacional. Primeira gestação, 22 semanas. Refere preocupação excessiva com saúde do bebê, medo do parto, dificuldade para relaxar. Pesquisas excessivas na internet. Sono inquieto.","objective":"Lúcida, orientada. Humor ansioso, afeto congruente. Fala sobre medos relacionados à gestação. Sem sintomas depressivos. Nega ideação suicida. PHQ-9: 6. GAD-7: 12.","assessment":"Transtorno de Ansiedade Generalizada leve, exacerbado pela gestação. Primigesta com medo normal amplificado.","plan":"1. Psicoeducação sobre ansiedade gestacional\\n2. Técnicas de relaxamento e mindfulness\\n3. Curso de preparação para parto\\n4. Evitar pesquisas em internet\\n5. Retorno em 30 dias - considerar psicoterapia se persistir"}'
WHERE Id = '6ECACC73-9EC2-4B76-8948-3AC89714BC2C';

-- 20/01/2026 - Seguimento gestação (cardio)
UPDATE Appointments SET 
SoapJson = '{"subjective":"Retorno opcional a pedido da paciente para tranquilização. 22 semanas de gestação. Continua assintomática. Pré-natal sem intercorrências.","objective":"BEG. PA: 108/68 mmHg, FC: 84 bpm. BCF: 148 bpm. Sopro sistólico funcional inalterado.","assessment":"Gestação tópica de 22 semanas, sem patologia cardiovascular. Paciente ansiosa mas clinicamente estável.","plan":"1. Reforçar que coração está saudável\\n2. Seguimento com obstetra\\n3. Sem necessidade de novos retornos cardiológicos"}'
WHERE Id = '3C8FAB75-8E28-4FF8-9F0C-DB5D74D2358D';

-- ============================================================
-- PEDRO COSTA - DIABÉTICO
-- ============================================================

-- 28/12/2025 - Avaliação DM
UPDATE Appointments SET 
SoapJson = '{"subjective":"Diabético tipo 2 há 10 anos, encaminhado para estratificação cardiovascular. Último HbA1c 7.2%. Nega dor torácica, dispneia ou claudicação. Refere formigamento em pés. Em uso regular das medicações.","objective":"Obeso (IMC 31), corado. PA: 142/90 mmHg, FC: 76 bpm. ACV: BRNF 2T, B4 presente. Pulsos pediais presentes, simétricos. Sensibilidade vibratória diminuída em pododáctilos.","assessment":"DM2 com controle glicêmico regular. Neuropatia diabética sensitiva. HAS associada. Alto risco cardiovascular (DM + HAS).","plan":"1. ECG e Ecocardiograma para estratificação\\n2. Doppler de carótidas\\n3. Otimizar controle pressórico (meta <130/80)\\n4. Retorno com exames"}',
AnamnesisJson = '{"chiefComplaint":"Avaliação cardiovascular - paciente diabético","presentIllnessHistory":"DM2 há 10 anos, bom controle recente (HbA1c 7.2%). Encaminhado pelo endocrinologista para estratificação CV. Assintomático do ponto de vista cardiovascular. Refere formigamento em pés há 1 ano.","pastMedicalHistory":"DM2 há 10 anos. Dislipidemia. Retinopatia diabética não proliferativa leve. Neuropatia sensitiva em pés.","familyHistory":"Pai DM2, faleceu de AVC aos 68 anos. Mãe HAS. Irmã DM2.","personalHistory":{"previousDiseases":"DM2, dislipidemia, sobrepeso","surgeries":"Nenhuma","hospitalizations":"Nenhuma CV","allergies":"Nega","currentMedications":"Metformina 850mg 2x, Glibenclamida 5mg, AAS 100mg, Atorvastatina 20mg","vaccinations":"Em dia"},"lifestyle":{"diet":"Irregular, dificuldade com restrição de carboidratos","physicalActivity":"Sedentário","smoking":"Ex-tabagista, parou há 5 anos (20 maços-ano)","alcohol":"Social","drugs":"Nega","sleep":"Regular"}}'
WHERE Id = '6F65F999-198B-405E-834D-5036DED973AB';

-- 09/01/2026 - Avaliação cardiovascular DM
UPDATE Appointments SET 
SoapJson = '{"subjective":"Retorna para estratificação cardiovascular. Realizou exames solicitados. Mantém formigamento em pés. Aderente às medicações. Iniciou caminhadas leves.","objective":"PA: 138/88 mmHg, FC: 74 bpm. ECG: ritmo sinusal, sem alterações isquêmicas. Eco: VE com geometria normal, FE 62%, disfunção diastólica grau I. Doppler carótidas: placas calcificadas em bulbos bilaterais, estenose <50%.","assessment":"DM2 com doença aterosclerótica subclínica (placas carotídeas). Disfunção diastólica grau I. Risco CV muito alto.","plan":"1. Intensificar controle de fatores de risco\\n2. Meta LDL <70 - aumentar Atorvastatina para 40mg\\n3. Otimizar PA - adicionar IECA (Enalapril 10mg)\\n4. Manter AAS\\n5. Retorno em 30 dias"}'
WHERE Id = '3AE49CF2-3991-4CEA-B82F-6999873D244B';

-- 16/01/2026 - Retorno com exames
UPDATE Appointments SET 
SoapJson = '{"subjective":"Retorno pós-ajuste medicamentoso. Tolerando Enalapril bem. Sem tosse. PA domiciliar entre 128-135/80-85. Caminhando 3x/semana. Glicemias mais estáveis.","objective":"PA: 128/82 mmHg, FC: 72 bpm. Labs: Glicemia 132, HbA1c 6.9% (melhora), LDL 98 (meta não atingida), Cr 0.9, K 4.3.","assessment":"DM2 com melhora do controle glicêmico. PA melhor controlada. LDL ainda acima da meta (<70).","plan":"1. Aumentar Atorvastatina para 80mg ou adicionar Ezetimiba\\n2. Manter esquema atual\\n3. Continuar atividade física\\n4. Retorno em 30 dias com perfil lipídico"}'
WHERE Id = '9EF50898-1B84-4B3A-92A4-4D98ADA8FBB0';

-- 19/01/2026 - Rastreio depressão (psiq)
UPDATE Appointments SET 
SoapJson = '{"subjective":"Encaminhado para rastreio de depressão - rotina em diabéticos. Nega humor deprimido. Refere frustração com dieta e restrições. Sono regular. Energia normal. Sem anedonia.","objective":"Lúcido, orientado, cooperativo. Humor eutímico. Afeto adequado. Sem sinais de depressão. PHQ-9: 4 (mínimo). GAD-7: 6 (leve).","assessment":"Rastreio de depressão negativo. Ansiedade leve, possivelmente relacionada ao manejo da doença crônica.","plan":"1. Sem necessidade de tratamento psiquiátrico no momento\\n2. Orientar sobre grupos de apoio para diabéticos\\n3. Retorno apenas se surgir sintomas\\n4. Manter acompanhamento endócrino e cardiológico"}'
WHERE Id = 'CC3F489F-4531-4A0C-98D4-28D058C0E3FF';

-- 21/01/2026 - Controle DM/HAS
UPDATE Appointments SET 
SoapJson = '{"subjective":"Controle de DM e HAS. PA domiciliar 120-128/78-82. Glicemias de jejum 110-130. Iniciou Ezetimiba há 10 dias, sem efeitos colaterais. Caminhando regularmente.","objective":"PA: 126/80 mmHg, FC: 70 bpm. Peso: 89.8kg (-200g). Exames: LDL 72 (meta atingida!), TG 145, HDL 45.","assessment":"DM2 e HAS com excelente controle. Meta de LDL atingida. Risco CV muito alto, mas fatores otimizados.","plan":"1. Manter esquema atual\\n2. Parabenizar paciente pela adesão\\n3. Manter atividade física\\n4. Próxima consulta em 3 meses"}'
WHERE Id = '16E81A55-7410-4895-8B73-FAD28E8A1CF2';

-- ============================================================
-- LÚCIA FERREIRA - DEPRESSÃO
-- ============================================================

-- 30/12/2025 - Primeira consulta depressão
UPDATE Appointments SET 
SoapJson = '{"subjective":"Primeira consulta. Viúva há 1 ano (esposo faleceu de câncer). Tristeza persistente há 8 meses com piora progressiva. Choro fácil, isolamento social. Abandonou atividades que gostava. Insônia terminal - acorda às 4h. Perda de 5kg em 3 meses. Pensamentos de morte: seria bom dormir e não acordar.","objective":"Emagrecida, postura retraída, pouco contato visual. Chora durante consulta. Humor deprimido, afeto embotado. Pensamento lentificado. Ideação passiva de morte sem planejamento. PHQ-9: 22 (grave). HAM-D: 24.","assessment":"Episódio Depressivo Grave sem sintomas psicóticos (F32.2). Ideação suicida passiva - risco moderado. Luto complicado.","plan":"1. Iniciar Mirtazapina 15mg à noite (pela insônia e inapetência)\\n2. Contrato de segurança\\n3. Orientar filha sobre sinais de alerta\\n4. Psicoterapia para luto\\n5. Retorno em 7 dias OBRIGATÓRIO"}',
AnamnesisJson = '{"chiefComplaint":"Tristeza profunda e desânimo há 8 meses","presentIllnessHistory":"Viúva há 1 ano - esposo faleceu de câncer após longa doença. Tristeza iniciou após o falecimento, inicialmente considerada luto normal. Há 8 meses, piora progressiva: choro fácil, isolamento total, abandono de hobbies (jardinagem, grupo de oração). Insônia terminal grave. Perda de 5kg. Pensamentos de morte passivos.","pastMedicalHistory":"HAS. Episódio depressivo leve há 20 anos, tratado por 1 ano. Menopausa aos 50. Osteopenia.","familyHistory":"Mãe com depressão grave, internação psiquiátrica. Irmã usa antidepressivo.","personalHistory":{"previousDiseases":"HAS, osteopenia, episódio depressivo prévio","surgeries":"Histerectomia (2010)","hospitalizations":"Nenhuma psiquiátrica","allergies":"Sulfa - reação cutânea grave","currentMedications":"Losartana 50mg, Cálcio + Vit D","vaccinations":"Em dia"},"lifestyle":{"diet":"Inapetência, alimentação pobre","physicalActivity":"Parou todas as atividades","smoking":"Nunca","alcohol":"Nunca","drugs":"Nunca","sleep":"Insônia terminal grave, dorme 4h/noite"}}'
WHERE Id = 'B12A0B5B-BFBF-4845-9F26-15B8557E139C';

-- 08/01/2026 - Avaliação depressão grave
UPDATE Appointments SET 
SoapJson = '{"subjective":"Primeira semana de Mirtazapina. Sono melhorou significativamente - dormindo 6-7h. Apetite retornando. Humor ainda muito triste. Mantém isolamento. Pensamentos de morte menos frequentes. Filha acompanhando de perto.","objective":"Melhor apresentação que consulta anterior. Mais contato visual. Ainda chorosa. Humor deprimido mas menos que antes. Sem ideação suicida ativa. PHQ-9: 18 (melhora de 4 pontos).","assessment":"Depressão grave em tratamento inicial. Melhora do sono e apetite (efeitos esperados da Mirtazapina). Humor ainda muito comprometido.","plan":"1. Aumentar Mirtazapina para 30mg\\n2. Manter acompanhamento intensivo\\n3. Iniciar psicoterapia para luto\\n4. Retorno em 7 dias"}'
WHERE Id = 'CC218030-FFA3-4C16-A541-E3E531DADBB4';

-- 15/01/2026 - Retorno depressão
UPDATE Appointments SET 
SoapJson = '{"subjective":"Segunda semana de tratamento. Continua melhora. Dormindo bem. Voltou a comer com a família. Chora menos. Aceitou convite para visitar irmã. Iniciou psicoterapia semanal. Sem pensamentos de morte.","objective":"Apresentação melhor. Cabelo arrumado, roupa diferente. Mais espontânea. Humor triste mas com momentos de leveza. PHQ-9: 14 (melhora progressiva).","assessment":"Depressão grave com resposta favorável ao tratamento. Melhora funcional inicial.","plan":"1. Manter Mirtazapina 30mg\\n2. Continuar psicoterapia\\n3. Estimular atividades prazerosas gradualmente\\n4. Retorno em 15 dias"}'
WHERE Id = 'E0A037C7-1D6C-4D31-AC20-F8DDB44BC0B6';

-- 20/01/2026 - Avaliação cardio palpitações
UPDATE Appointments SET 
SoapJson = '{"subjective":"Encaminhada pelo psiquiatra para avaliação de palpitações. Em tratamento para depressão com Mirtazapina. Refere palpitações ocasionais, sem dor torácica ou dispneia. Boa evolução psiquiátrica.","objective":"BEG, melhor que atendimentos anteriores. PA: 128/80 mmHg, FC: 86 bpm regular. ECG: ritmo sinusal, FC 82, PR 160ms, QTc 420ms (normal). Sem alterações de repolarização.","assessment":"Palpitações possivelmente relacionadas à ansiedade residual. ECG normal. Mirtazapina não causa arritmias significativas. Sem contraindicação cardiovascular ao tratamento psiquiátrico.","plan":"1. Tranquilizar sobre normalidade cardíaca\\n2. Palpitações devem melhorar com evolução do tratamento psiquiátrico\\n3. Sem necessidade de exames adicionais\\n4. Seguimento com psiquiatria"}'
WHERE Id = 'FDF34B8F-EB30-49AE-A8D7-9E3DE132289B';

-- 22/01/2026 - Melhora depressão
UPDATE Appointments SET 
SoapJson = '{"subjective":"Quarta semana de tratamento. Melhora significativa do humor. Voltou a cuidar do jardim. Participa do grupo de oração novamente. Dormindo bem, apetite normal. Sente saudades do marido mas consegue lembrar dele sem chorar tanto. Sem pensamentos negativos.","objective":"Bem apresentada, sorridente por momentos. Contato visual adequado. Humor eutímico a levemente triste. Afeto modulado. PHQ-9: 8 (depressão leve). HAM-D: 10.","assessment":"Depressão em remissão parcial. Excelente resposta à Mirtazapina 30mg + psicoterapia. Processo de luto evoluindo adequadamente.","plan":"1. Manter Mirtazapina 30mg\\n2. Manter psicoterapia - espaçar para quinzenal\\n3. Estimular atividades sociais\\n4. Retorno em 30 dias\\n5. Tratamento deve durar mínimo 12 meses"}'
WHERE Id = 'E1194F79-CA05-479C-A381-32615CAB4C57';

-- ============================================================
-- FIM DO SCRIPT DE CORREÇÃO
-- ============================================================
