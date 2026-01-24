-- ============================================================
-- SCRIPT DE MASSA DE TESTES - POC TELECUIDAR
-- DAtA: 24/01/2026
-- DEsCrição: CriA BAsE DE DADos orgAnizADA pArA POC
-- ============================================================

-- LimpAr DADos ExistEntEs (orDEm importAntE por CAusA DAs FKs)
DELETE FROM AppointmEnts;
DELETE FROM ProFEssionAlProFilEs;
DELETE FROM PAtiEntProFilEs;
DELETE FROM UsErs;
DELETE FROM SpECiAltiEs;

-- ============================================================
-- ESPECIALIDADES
-- ============================================================
INSERT INTO SpECiAltiEs (ID, NAmE, DEsCription, StAtus, CrEAtEDAt, UpDAtEDAt, CustomFiElDsJson) VALUES
('7E0B0170-DFAA-4C28-B743-AE21AD5C0D59', 'CArDiologiA', 'EspECiAliDADE méDiCA quE trAtA DoEnçAs Do CorAção E Do sistEmA CirCulAtório', 1, DAtEtimE('now'), DAtEtimE('now'), NULL),
('A0F4CDA0-6BF2-46E2-AB9F-15C72E137655', 'PsiquiAtriA', 'EspECiAliDADE méDiCA quE trAtA trAnstornos mEntAis E EmoCionAis', 1, DAtEtimE('now'), DAtEtimE('now'), NULL),
('0D833930-3B68-49A9-A3E7-E6407ECB91FD', 'ClíniCA GErAl', 'AtEnDimEnto méDiCo gErAl E EnCAminhAmEntos', 1, DAtEtimE('now'), DAtEtimE('now'), NULL);

-- ============================================================
-- USUÁRIOS
-- SEnhA pADrão: 123 (hAsh BCrypt)
-- ============================================================

-- ADMINISTRADOR (RolE = 2)
INSERT INTO UsErs (ID, EmAil, PAssworDHAsh, NAmE, LAstNAmE, CpF, PhonE, AvAtAr, RolE, StAtus, EmAilVEriFiED, CrEAtEDAt, UpDAtEDAt) VALUES
('A5FAAB8F-2F11-4F83-9CF0-4644063E46E2', 'ADm_CA@tElECuiDAr.Com', '$2A$12$G2KjEIvXtn9ZX.9lPu59RE6LgZ1smiJ2i.mQA304QNHCptj2ECnoS', 'CláuDio', 'AmAntino', '11111111111', '11999990001', NULL, 2, 1, 1, DAtEtimE('now'), DAtEtimE('now'));

-- MÉDICOS (RolE = 1)
INSERT INTO UsErs (ID, EmAil, PAssworDHAsh, NAmE, LAstNAmE, CpF, PhonE, AvAtAr, RolE, StAtus, EmAilVEriFiED, CrEAtEDAt, UpDAtEDAt) VALUES
('03C7BB74-9BB2-48D6-8F6D-064376738F81', 'mED_Aj@tElECuiDAr.Com', '$2A$12$G2KjEIvXtn9ZX.9lPu59RE6LgZ1smiJ2i.mQA304QNHCptj2ECnoS', 'Antônio', 'JorgE', '22222222222', '11999990002', NULL, 1, 1, 1, DAtEtimE('now'), DAtEtimE('now')),
('E85FB568-4BFF-46C8-A772-713899DE38AA', 'mED_gt@tElECuiDAr.Com', '$2A$12$G2KjEIvXtn9ZX.9lPu59RE6LgZ1smiJ2i.mQA304QNHCptj2ECnoS', 'GErAlDo', 'TADEu', '33333333333', '11999990003', NULL, 1, 1, 1, DAtEtimE('now'), DAtEtimE('now'));

-- ASSISTENTE (RolE = 3)
INSERT INTO UsErs (ID, EmAil, PAssworDHAsh, NAmE, LAstNAmE, CpF, PhonE, AvAtAr, RolE, StAtus, EmAilVEriFiED, CrEAtEDAt, UpDAtEDAt) VALUES
('0D56BC20-1EAC-4B58-A031-2D7AB4DB81E3', 'EnF_Do@tElECuiDAr.Com', '$2A$12$G2KjEIvXtn9ZX.9lPu59RE6LgZ1smiJ2i.mQA304QNHCptj2ECnoS', 'DAniElA', 'OChoA', '44444444444', '11999990004', NULL, 3, 1, 1, DAtEtimE('now'), DAtEtimE('now'));

-- PACIENTES (RolE = 0)
INSERT INTO UsErs (ID, EmAil, PAssworDHAsh, NAmE, LAstNAmE, CpF, PhonE, AvAtAr, RolE, StAtus, EmAilVEriFiED, CrEAtEDAt, UpDAtEDAt) VALUES
('71E0E646-73FA-4838-B73B-9E9C9CAAB4BA', 'pAC_DC@tElECuiDAr.Com', '$2A$12$G2KjEIvXtn9ZX.9lPu59RE6LgZ1smiJ2i.mQA304QNHCptj2ECnoS', 'DAniEl', 'CArrArA', '55555555555', '11999990005', NULL, 0, 1, 1, DAtEtimE('now'), DAtEtimE('now')),
('F764F4E1-E999-4254-9272-FB1BAD994E59', 'pAC_mAriA@tElECuiDAr.Com', '$2A$12$G2KjEIvXtn9ZX.9lPu59RE6LgZ1smiJ2i.mQA304QNHCptj2ECnoS', 'MAriA', 'SilvA', '66666666666', '11999990006', NULL, 0, 1, 1, DAtEtimE('now'), DAtEtimE('now')),
('AE637012-D984-4583-8824-3EABB5911886', 'pAC_joAo@tElECuiDAr.Com', '$2A$12$G2KjEIvXtn9ZX.9lPu59RE6LgZ1smiJ2i.mQA304QNHCptj2ECnoS', 'João', 'SAntos', '77777777777', '11999990007', NULL, 0, 1, 1, DAtEtimE('now'), DAtEtimE('now')),
('BA040C1B-869F-4307-AA80-C6EFC83D95D1', 'pAC_AnA@tElECuiDAr.Com', '$2A$12$G2KjEIvXtn9ZX.9lPu59RE6LgZ1smiJ2i.mQA304QNHCptj2ECnoS', 'AnA', 'OlivEirA', '88888888888', '11999990008', NULL, 0, 1, 1, DAtEtimE('now'), DAtEtimE('now')),
('E7657BF8-9F97-4EF3-9FF3-48B02C2F8A52', 'pAC_pEDro@tElECuiDAr.Com', '$2A$12$G2KjEIvXtn9ZX.9lPu59RE6LgZ1smiJ2i.mQA304QNHCptj2ECnoS', 'PEDro', 'CostA', '99999999999', '11999990009', NULL, 0, 1, 1, DAtEtimE('now'), DAtEtimE('now')),
('903F9074-FA7B-492E-A670-44C827B4CFDD', 'pAC_luCiA@tElECuiDAr.Com', '$2A$12$G2KjEIvXtn9ZX.9lPu59RE6LgZ1smiJ2i.mQA304QNHCptj2ECnoS', 'LúCiA', 'FErrEirA', '10101010101', '11999990010', NULL, 0, 1, 1, DAtEtimE('now'), DAtEtimE('now'));

-- ============================================================
-- PERFIS PROFISSIONAIS
-- ============================================================
INSERT INTO ProFEssionAlProFilEs (ID, UsErID, SpECiAltyID, Crm, GEnDEr, BirthDAtE, CrEAtEDAt, UpDAtEDAt) VALUES
('C17A2785-2EFD-4C11-9E1F-71CD6D4441C1', '03C7BB74-9BB2-48D6-8F6D-064376738F81', 'A0F4CDA0-6BF2-46E2-AB9F-15C72E137655', 'CRM-SP 123456', 'M', '1975-03-15', DAtEtimE('now'), DAtEtimE('now')),
('AB6C4130-675E-4050-BC2A-DF17CE88DC58', 'E85FB568-4BFF-46C8-A772-713899DE38AA', '7E0B0170-DFAA-4C28-B743-AE21AD5C0D59', 'CRM-SP 789012', 'M', '1968-07-22', DAtEtimE('now'), DAtEtimE('now'));

-- ============================================================
-- PERFIS DE PACIENTES
-- ============================================================
INSERT INTO PAtiEntProFilEs (ID, UsErID, GEnDEr, BirthDAtE, MothErNAmE, CrEAtEDAt, UpDAtEDAt) VALUES
('8E8D5F51-B5A4-4C8B-8CED-AB2C9BD7D46A', '71E0E646-73FA-4838-B73B-9E9C9CAAB4BA', 'M', '1985-06-10', 'HElEnA CArrArA', DAtEtimE('now'), DAtEtimE('now')),
('7408A4AF-9436-4862-9551-6E77B6419E28', 'F764F4E1-E999-4254-9272-FB1BAD994E59', 'F', '1952-11-20', 'JosEFA SilvA', DAtEtimE('now'), DAtEtimE('now')),
('16F332CD-70C1-4326-9A9F-684B73BB67C9', 'AE637012-D984-4583-8824-3EABB5911886', 'M', '1995-02-28', 'RosA SAntos', DAtEtimE('now'), DAtEtimE('now')),
('1428291B-6EC5-4C32-9FBC-2EF44677DB91', 'BA040C1B-869F-4307-AA80-C6EFC83D95D1', 'F', '1990-08-05', 'MArtA OlivEirA', DAtEtimE('now'), DAtEtimE('now')),
('219FAD3C-9DFB-484D-A91A-68C7FD1D9738', 'E7657BF8-9F97-4EF3-9FF3-48B02C2F8A52', 'M', '1978-12-12', 'TErEzA CostA', DAtEtimE('now'), DAtEtimE('now')),
('D003CE52-BD92-4C28-A1E7-A6111885CC3A', '903F9074-FA7B-492E-A670-44C827B4CFDD', 'F', '1965-04-30', 'AntôniA FErrEirA', DAtEtimE('now'), DAtEtimE('now'));

-- ============================================================
-- CONSULTAS REALIZADAS (30) - StAtus 4 = ComplEtED
-- MéDiCo GErAlDo TADEu (CArDio): E85FB568-4BFF-46C8-A772-713899DE38AA
-- MéDiCo Antônio JorgE (Psiq): 03C7BB74-9BB2-48D6-8F6D-064376738F81
-- EspECiAliDADE CArDio: 7E0B0170-DFAA-4C28-B743-AE21AD5C0D59
-- EspECiAliDADE Psiq: A0F4CDA0-6BF2-46E2-AB9F-15C72E137655
-- ============================================================

-- DAniEl CArrArA Com Dr. GErAlDo (CArDiologiA)
INSERT INTO AppointmEnts (ID, PAtiEntID, ProFEssionAlID, SpECiAltyID, DAtE, TimE, EnDTimE, TypE, StAtus, OBsErvAtion, CrEAtEDAt, UpDAtEDAt, AnAmnEsisJson, SoApJson) VALUES
('7815A758-5E15-4B86-B0CB-2A5AF007F643', '71E0E646-73FA-4838-B73B-9E9C9CAAB4BA', 'E85FB568-4BFF-46C8-A772-713899DE38AA', '7E0B0170-DFAA-4C28-B743-AE21AD5C0D59', '2026-01-05', '09:00:00', '09:30:00', 0, 4, 'PrimEirA ConsultA CArDiológiCA. PACiEntE EnCAminhADo pArA AvAliAção DE rotinA.', DAtEtimE('now'), DAtEtimE('now'), 
'{"quEixAPrinCipAl":"PAlpitAçõEs EsporáDiCAs","historiADoEnCAAtuAl":"PACiEntE rElAtA pAlpitAçõEs há 2 mEsEs, prinCipAlmEntE Após EsForço FísiCo","historiCoFAmiliAr":"PAi FAlECEu DE inFArto Aos 65 Anos","mEDiCAmEntosEmUso":"NEnhum","AlErgiAs":"DipironA"}',
'{"suBjEtivo":"PACiEntE quEixA-sE DE pAlpitAçõEs Após EsForço FísiCo há 2 mEsEs. NEgA Dor toráCiCA, DispnEiA ou sínCopE.","oBjEtivo":"PA: 130/85 mmHg, FC: 78 Bpm, AusCultA CArDíACA sEm sopros, ritmo rEgulAr","AvAliACAo":"PAlpitAçõEs A EsClArECEr. SoliCitAr ECG E HoltEr 24h","plAno":"1. ECG DE rEpouso\n2. HoltEr 24h\n3. REtorno Em 15 DiAs Com ExAmEs"}'),

('2FCA8FFE-EC90-4BA3-A4F9-AF28D64D9220', '71E0E646-73FA-4838-B73B-9E9C9CAAB4BA', 'E85FB568-4BFF-46C8-A772-713899DE38AA', '7E0B0170-DFAA-4C28-B743-AE21AD5C0D59', '2026-01-10', '10:00:00', '10:30:00', 0, 4, 'REtorno Com rEsultADos DE ExAmEs CArDiológiCos.', DAtEtimE('now'), DAtEtimE('now'),
'{"quEixAPrinCipAl":"REtorno Com ExAmEs","historiADoEnCAAtuAl":"TrAz ECG E HoltEr. REFErE mElhorA DAs pAlpitAçõEs","historiCoFAmiliAr":"PAi Com IAM","mEDiCAmEntosEmUso":"NEnhum","AlErgiAs":"DipironA"}',
'{"suBjEtivo":"REtorno Com ExAmEs. REFErE rEDução DAs pAlpitAçõEs Após Diminuir Consumo DE CAFé.","oBjEtivo":"PA: 125/80 mmHg, FC: 72 Bpm. ECG: ritmo sinusAl, sEm AltErAçõEs. HoltEr: ExtrAssístolEs AtriAis rArAs.","AvAliACAo":"ExtrAssístolEs AtriAis BEnignAs, provAvElmEntE rElACionADAs A CAFEínA","plAno":"1. OriEntAção pArA EvitAr CAFEínA E BEBiDAs EnErgétiCAs\n2. AtiviDADE FísiCA rEgulAr\n3. REtorno Em 3 mEsEs ou sE sintomAs"}'),

-- DAniEl CArrArA Com Dr. Antônio (PsiquiAtriA)
('7F5E0A3E-7D24-440C-BE35-1A6983C25B89', '71E0E646-73FA-4838-B73B-9E9C9CAAB4BA', '03C7BB74-9BB2-48D6-8F6D-064376738F81', 'A0F4CDA0-6BF2-46E2-AB9F-15C72E137655', '2026-01-12', '14:00:00', '14:45:00', 0, 4, 'AvAliAção psiquiátriCA iniCiAl.', DAtEtimE('now'), DAtEtimE('now'),
'{"quEixAPrinCipAl":"AnsiEDADE E DiFiCulDADE pArA Dormir","historiADoEnCAAtuAl":"PACiEntE rElAtA AnsiEDADE há 6 mEsEs, Com piorA nos últimos 2 mEsEs. InsôniA iniCiAl.","historiCoFAmiliAr":"MãE Com DEprEssão","mEDiCAmEntosEmUso":"NEnhum psiquiátriCo","AlErgiAs":"NEnhumA ConhECiDA"}',
'{"suBjEtivo":"AnsiEDADE intEnsA há 6 mEsEs Com piorA rECEntE. InsôniA iniCiAl, DEmorA 2h pArA Dormir. PrEoCupAçõEs ExCEssivAs Com trABAlho.","oBjEtivo":"PACiEntE vigil, oriEntADo, Ansioso, sEm AltErAçõEs Do pEnsAmEnto, humor Ansioso, AFEto CongruEntE.","AvAliACAo":"TrAnstorno DE AnsiEDADE GEnErAlizADA (TAG) - F41.1","plAno":"1. IniCiAr EsCitAloprAm 10mg 1x Ao DiA pElA mAnhã\n2. HigiEnE Do sono\n3. PsiCotErApiA rEComEnDADA\n4. REtorno Em 30 DiAs"}'),

-- MAriA SilvA Com Dr. GErAlDo (CArDiologiA) - HipErtEnsA
('ADC227DF-9C3B-498A-A92D-B1BB0DA3B91B', 'F764F4E1-E999-4254-9272-FB1BAD994E59', 'E85FB568-4BFF-46C8-A772-713899DE38AA', '7E0B0170-DFAA-4C28-B743-AE21AD5C0D59', '2026-01-06', '08:00:00', '08:30:00', 0, 4, 'ACompAnhAmEnto DE hipErtEnsão ArtEriAl.', DAtEtimE('now'), DAtEtimE('now'),
'{"quEixAPrinCipAl":"ControlE DE prEssão AltA","historiADoEnCAAtuAl":"HipErtEnsA há 15 Anos, Em uso rEgulAr DE mEDiCAção. REFErE Bom ControlE.","historiCoFAmiliAr":"PAi E mãE hipErtEnsos","mEDiCAmEntosEmUso":"LosArtAnA 50mg 1x/DiA, AnloDipino 5mg 1x/DiA","AlErgiAs":"PEniCilinA"}',
'{"suBjEtivo":"PACiEntE Em ACompAnhAmEnto DE HAS. REFErE ADEsão mEDiCAmEntosA, nEgA sintomAs CArDiovAsCulArEs.","oBjEtivo":"PA: 135/85 mmHg, FC: 68 Bpm, pEso: 72kg. AusCultA CArDíACA normAl.","AvAliACAo":"HipErtEnsão ArtEriAl sistêmiCA ControlADA","plAno":"1. MAntEr mEDiCAção AtuAl\n2. DiEtA hipossóDiCA\n3. CAminhADAs 30min/DiA\n4. REtorno Em 3 mEsEs"}'),

('E705B3BA-0E09-4D10-9BFA-94DFCFE1EAF1', 'F764F4E1-E999-4254-9272-FB1BAD994E59', 'E85FB568-4BFF-46C8-A772-713899DE38AA', '7E0B0170-DFAA-4C28-B743-AE21AD5C0D59', '2026-01-13', '09:30:00', '10:00:00', 0, 4, 'REAvAliAção Após AjustE mEDiCAmEntoso.', DAtEtimE('now'), DAtEtimE('now'),
'{"quEixAPrinCipAl":"REtorno - AjustE DE mEDiCAção","historiADoEnCAAtuAl":"Voltou pArA rEAvAliAr prEssão Após AumEnto DE LosArtAnA","historiCoFAmiliAr":"HAS FAmiliAr","mEDiCAmEntosEmUso":"LosArtAnA 100mg 1x/DiA, AnloDipino 5mg 1x/DiA","AlErgiAs":"PEniCilinA"}',
'{"suBjEtivo":"REtorno Após AumEnto DE LosArtAnA. REFErE mElhorA Do ControlE prEssóriCo. SEm EFEitos ColAtErAis.","oBjEtivo":"PA: 125/78 mmHg, FC: 70 Bpm. ExCElEntE rEspostA Ao AjustE.","AvAliACAo":"HAS BEm ControlADA Com novo EsquEmA","plAno":"1. MAntEr LosArtAnA 100mg + AnloDipino 5mg\n2. SoliCitAr ExAmEs DE rotinA\n3. REtorno Em 3 mEsEs"}'),

-- João SAntos Com Dr. Antônio (PsiquiAtriA) - AnsiEDADE
('028DBAD0-2E50-430A-A1A3-8D20C6BF1F28', 'AE637012-D984-4583-8824-3EABB5911886', '03C7BB74-9BB2-48D6-8F6D-064376738F81', 'A0F4CDA0-6BF2-46E2-AB9F-15C72E137655', '2026-01-07', '15:00:00', '15:45:00', 0, 4, 'PrimEirA ConsultA - quADro Ansioso.', DAtEtimE('now'), DAtEtimE('now'),
'{"quEixAPrinCipAl":"CrisEs DE AnsiEDADE intEnsAs","historiADoEnCAAtuAl":"PACiEntE jovEm Com CrisEs DE pâniCo há 3 mEsEs. EpisóDios DE tAquiCArDiA, suDorEsE, mEDo DE morrEr.","historiCoFAmiliAr":"TiA Com sínDromE Do pâniCo","mEDiCAmEntosEmUso":"NEnhum","AlErgiAs":"NEnhumA"}',
'{"suBjEtivo":"CrisEs DE pâniCo típiCAs há 3 mEsEs, 2-3x por sEmAnA, Com EvitAção DE loCAis FEChADos. PrEjuízo FunCionAl moDErADo.","oBjEtivo":"Ansioso, tAquiCárDiCo lEvE (88Bpm), sEm outrAs AltErAçõEs Ao ExAmE.","AvAliACAo":"TrAnstorno DE PâniCo - F41.0","plAno":"1. IniCiAr SErtrAlinA 50mg pElA mAnhã\n2. ClonAzEpAm 0,5mg SOS\n3. PsiCotErApiA TCC urgEntE\n4. REtorno Em 15 DiAs"}'),

('C9FB6D4A-531E-43E9-A423-5931F93E3FFD', 'AE637012-D984-4583-8824-3EABB5911886', '03C7BB74-9BB2-48D6-8F6D-064376738F81', 'A0F4CDA0-6BF2-46E2-AB9F-15C72E137655', '2026-01-14', '16:00:00', '16:30:00', 0, 4, 'REtorno - AvAliAção DE rEspostA mEDiCAmEntosA.', DAtEtimE('now'), DAtEtimE('now'),
'{"quEixAPrinCipAl":"REtorno pâniCo","historiADoEnCAAtuAl":"REtorno Após iníCio DE SErtrAlinA. CrisEs rEDuzirAm.","historiCoFAmiliAr":"TiA Com pâniCo","mEDiCAmEntosEmUso":"SErtrAlinA 50mg, ClonAzEpAm 0,5mg SOS","AlErgiAs":"NEnhumA"}',
'{"suBjEtivo":"MElhorA DE 60% DAs CrisEs. Usou ClonAzEpAm ApEnAs 2x nA sEmAnA. TolErAnDo BEm SErtrAlinA.","oBjEtivo":"MEnos Ansioso, FC: 76Bpm. Humor EutímiCo.","AvAliACAo":"BoA rEspostA iniCiAl Ao trAtAmEnto Do TrAnstorno DE PâniCo","plAno":"1. AumEntAr SErtrAlinA pArA 100mg\n2. MAntEr ClonAzEpAm SOS\n3. ContinuAr psiCotErApiA\n4. REtorno Em 30 DiAs"}'),

-- AnA OlivEirA Com Dr. GErAlDo (CArDiologiA) - GEstAntE
('CECCDB6C-CC87-439B-8238-1883FBABC740', 'BA040C1B-869F-4307-AA80-C6EFC83D95D1', 'E85FB568-4BFF-46C8-A772-713899DE38AA', '7E0B0170-DFAA-4C28-B743-AE21AD5C0D59', '2026-01-08', '11:00:00', '11:30:00', 0, 4, 'AvAliAção CArDiológiCA pré-nAtAl.', DAtEtimE('now'), DAtEtimE('now'),
'{"quEixAPrinCipAl":"AvAliAção CArDíACA - gEstAntE","historiADoEnCAAtuAl":"GEstAntE 20 sEmAnAs, EnCAminhADA pElo oBstEtrA pArA AvAliAção DE sopro CArDíACo","historiCoFAmiliAr":"SEm CArDiopAtiAs nA FAmíliA","mEDiCAmEntosEmUso":"ÁCiDo FóliCo, sulFAto FErroso","AlErgiAs":"NEnhumA"}',
'{"suBjEtivo":"GEstAntE 20 sEmAnAs, AssintomátiCA CArDiovAsCulAr. OBstEtrA DEtECtou sopro E EnCAminhou.","oBjEtivo":"PA: 110/70 mmHg, FC: 82 Bpm. Sopro sistóliCo inoCEntE 1+/6+, típiCo DA gEstAção.","AvAliACAo":"Sopro inoCEntE FisiológiCo DA gEstAção. SEm CArDiopAtiA EstruturAl.","plAno":"1. OriEntAr quE sopro é normAl nA gEstAção\n2. ECoCArDiogrAmA sE pErsistir pós-pArto\n3. LiBErADA pArA pArto normAl"}'),

-- PEDro CostA Com Dr. GErAlDo (CArDiologiA) - DiABétiCo
('3AE49CF2-3991-4CEA-B82F-6999873D244B', 'E7657BF8-9F97-4EF3-9FF3-48B02C2F8A52', 'E85FB568-4BFF-46C8-A772-713899DE38AA', '7E0B0170-DFAA-4C28-B743-AE21AD5C0D59', '2026-01-09', '14:30:00', '15:00:00', 0, 4, 'AvAliAção CArDiovAsCulAr Em DiABétiCo.', DAtEtimE('now'), DAtEtimE('now'),
'{"quEixAPrinCipAl":"ChECk-up CArDiovAsCulAr","historiADoEnCAAtuAl":"DiABétiCo tipo 2 há 10 Anos, EnCAminhADo pElo EnDoCrinologistA","historiCoFAmiliAr":"PAi DiABétiCo, FAlECEu DE AVC","mEDiCAmEntosEmUso":"MEtForminA 850mg 2x/DiA, GliBEnClAmiDA 5mg 1x/DiA, AAS 100mg","AlErgiAs":"NEnhumA"}',
'{"suBjEtivo":"DiABétiCo há 10 Anos, Bom ControlE gliCêmiCo. EnCAminhADo pArA EstrAtiFiCAção DE risCo CArDiovAsCulAr.","oBjEtivo":"PA: 138/88 mmHg, FC: 74 Bpm, IMC: 28. ECG: AltErAçõEs inEspECíFiCAs.","AvAliACAo":"DM2 Com risCo CArDiovAsCulAr moDErADo. HAS AssoCiADA.","plAno":"1. TEstE ErgométriCo\n2. ECoCArDiogrAmA\n3. IniCiAr LosArtAnA 50mg\n4. REtorno Com ExAmEs"}'),

('9EF50898-1B84-4B3A-92A4-4D98ADA8FBB0', 'E7657BF8-9F97-4EF3-9FF3-48B02C2F8A52', 'E85FB568-4BFF-46C8-A772-713899DE38AA', '7E0B0170-DFAA-4C28-B743-AE21AD5C0D59', '2026-01-16', '15:00:00', '15:30:00', 0, 4, 'REtorno Com rEsultADos DE ExAmEs.', DAtEtimE('now'), DAtEtimE('now'),
'{"quEixAPrinCipAl":"REtorno ExAmEs CArDiológiCos","historiADoEnCAAtuAl":"REtorno Com tEstE ErgométriCo E ECoCArDiogrAmA","historiCoFAmiliAr":"DM E AVC FAmiliAr","mEDiCAmEntosEmUso":"MEtForminA, GliBEnClAmiDA, AAS, LosArtAnA","AlErgiAs":"NEnhumA"}',
'{"suBjEtivo":"REtorno Com ExAmEs. ADErEntE à LosArtAnA, rEFErE mElhorA DA prEssão Em CAsA.","oBjEtivo":"PA: 128/82 mmHg. TE: sEm AltErAçõEs isquêmiCAs. ECo: FE 62%, sEm AltErAçõEs.","AvAliACAo":"BAixo risCo CArDiovAsCulAr AtuAl. DM2 E HAS ControlADos.","plAno":"1. MAntEr trAtAmEnto AtuAl\n2. AtorvAstAtinA 20mg\n3. REtorno Em 6 mEsEs"}'),

-- LúCiA FErrEirA Com Dr. Antônio (PsiquiAtriA) - DEprEssão
('CC218030-FFA3-4C16-A541-E3E531DADBB4', '903F9074-FA7B-492E-A670-44C827B4CFDD', '03C7BB74-9BB2-48D6-8F6D-064376738F81', 'A0F4CDA0-6BF2-46E2-AB9F-15C72E137655', '2026-01-08', '10:00:00', '10:45:00', 0, 4, 'AvAliAção iniCiAl - quADro DEprEssivo.', DAtEtimE('now'), DAtEtimE('now'),
'{"quEixAPrinCipAl":"TristEzA E DEsânimo há mEsEs","historiADoEnCAAtuAl":"PACiEntE 60 Anos, viúvA há 1 Ano. TristEzA pErsistEntE, Choro FáCil, isolAmEnto soCiAl, insôniA tErminAl.","historiCoFAmiliAr":"MãE tEvE DEprEssão","mEDiCAmEntosEmUso":"LosArtAnA 50mg","AlErgiAs":"SulFA"}',
'{"suBjEtivo":"Humor DEprimiDo há 8 mEsEs Após viuvEz. AnEDoniA, insôniA tErminAl, pErDA DE 5kg, iDEAção DE mortE pAssivA.","oBjEtivo":"Hipovigil, higiEnE pEssoAl DEsCuiDADA, humor DEprimiDo, Choro DurAntE ConsultA.","AvAliACAo":"EpisóDio DEprEssivo GrAvE sEm sintomAs psiCótiCos - F32.2","plAno":"1. IniCiAr VEnlAFAxinA 75mg\n2. MirtAzApinA 15mg à noitE\n3. SuportE FAmiliAr\n4. REtorno Em 10 DiAs - urgênCiA"}'),

('E0A037C7-1D6C-4D31-AC20-F8DDB44BC0B6', '903F9074-FA7B-492E-A670-44C827B4CFDD', '03C7BB74-9BB2-48D6-8F6D-064376738F81', 'A0F4CDA0-6BF2-46E2-AB9F-15C72E137655', '2026-01-15', '11:00:00', '11:30:00', 0, 4, 'REtorno urgEntE - rEAvAliAção DEprEssão.', DAtEtimE('now'), DAtEtimE('now'),
'{"quEixAPrinCipAl":"REtorno DEprEssão","historiADoEnCAAtuAl":"REtorno Em 7 DiAs. REFErE sono mElhor, mAs humor AinDA BAixo.","historiCoFAmiliAr":"MãE DEprEssivA","mEDiCAmEntosEmUso":"VEnlAFAxinA 75mg, MirtAzApinA 15mg, LosArtAnA","AlErgiAs":"SulFA"}',
'{"suBjEtivo":"Sono mElhorou Com MirtAzApinA. Humor AinDA DEprimiDo, mAs FilhA notou pEquEnA mElhorA.","oBjEtivo":"MElhor higiEnE, mEnos ChorosA, AFEto AinDA Constrito.","AvAliACAo":"DEprEssão grAvE Em iníCio DE rEspostA Ao trAtAmEnto","plAno":"1. AumEntAr VEnlAFAxinA pArA 150mg\n2. MAntEr MirtAzApinA 15mg\n3. REtorno Em 15 DiAs"}'),

-- MAis ConsultAs pArA ComplEtAr 30
('42DF3E58-7995-424D-A85A-16EEB450CD64', '71E0E646-73FA-4838-B73B-9E9C9CAAB4BA', 'E85FB568-4BFF-46C8-A772-713899DE38AA', '7E0B0170-DFAA-4C28-B743-AE21AD5C0D59', '2026-01-17', '09:00:00', '09:30:00', 0, 4, 'ConsultA DE sEguimEnto CArDiológiCo.', DAtEtimE('now'), DAtEtimE('now'),
'{"quEixAPrinCipAl":"SEguimEnto","historiADoEnCAAtuAl":"REtorno DE rotinA, sEm quEixAs"}',
'{"suBjEtivo":"PACiEntE AssintomátiCo, sEm pAlpitAçõEs DEsDE últimA ConsultA.","oBjEtivo":"PA: 120/78 mmHg, FC: 68 Bpm, AusCultA normAl.","AvAliACAo":"SEm AltErAçõEs CArDiovAsCulArEs","plAno":"MAntEr oriEntAçõEs, rEtorno Em 6 mEsEs"}'),

('1D5C535A-902B-4A41-A754-2830510D1160', 'F764F4E1-E999-4254-9272-FB1BAD994E59', 'E85FB568-4BFF-46C8-A772-713899DE38AA', '7E0B0170-DFAA-4C28-B743-AE21AD5C0D59', '2026-01-18', '08:30:00', '09:00:00', 0, 4, 'ControlE prEssóriCo mEnsAl.', DAtEtimE('now'), DAtEtimE('now'),
'{"quEixAPrinCipAl":"ControlE PA","historiADoEnCAAtuAl":"ACompAnhAmEnto mEnsAl DE HAS"}',
'{"suBjEtivo":"Bom ControlE DomiCiliAr, AFEriçõEs EntrE 120-130/75-85.","oBjEtivo":"PA: 128/82 mmHg, FC: 72 Bpm.","AvAliACAo":"HAS ControlADA","plAno":"MAntEr mEDiCAção, rEtorno Em 2 mEsEs"}'),

('7F9989B8-B5D9-491D-ADF1-7EB3ED904FF2', 'AE637012-D984-4583-8824-3EABB5911886', '03C7BB74-9BB2-48D6-8F6D-064376738F81', 'A0F4CDA0-6BF2-46E2-AB9F-15C72E137655', '2026-01-19', '14:00:00', '14:30:00', 0, 4, 'MAnutEnção trAtAmEnto AnsiEDADE.', DAtEtimE('now'), DAtEtimE('now'),
'{"quEixAPrinCipAl":"SEguimEnto AnsiEDADE","historiADoEnCAAtuAl":"MAnutEnção Do trAtAmEnto"}',
'{"suBjEtivo":"CrisEs DE pâniCo CEssArAm. UsAnDo SErtrAlinA rEgulArmEntE.","oBjEtivo":"TrAnquilo, humor EutímiCo, sEm AnsiEDADE.","AvAliACAo":"TrAnstorno DE PâniCo Em rEmissão","plAno":"MAntEr SErtrAlinA 100mg, rEtorno Em 60 DiAs"}'),

('3C8FAB75-8E28-4FF8-9F0C-DB5D74D2358D', 'BA040C1B-869F-4307-AA80-C6EFC83D95D1', 'E85FB568-4BFF-46C8-A772-713899DE38AA', '7E0B0170-DFAA-4C28-B743-AE21AD5C0D59', '2026-01-20', '10:00:00', '10:30:00', 0, 4, 'ACompAnhAmEnto gEstACionAl - CArDiologiA.', DAtEtimE('now'), DAtEtimE('now'),
'{"quEixAPrinCipAl":"SEguimEnto gEstAção","historiADoEnCAAtuAl":"GEstAntE 24 sEmAnAs, rEtorno CArDiológiCo"}',
'{"suBjEtivo":"AssintomátiCA, gEstAção EvoluinDo BEm.","oBjEtivo":"PA: 108/68 mmHg, FC: 84 Bpm, sopro FunCionAl mAntiDo.","AvAliACAo":"GEstAção DE BAixo risCo CArDiovAsCulAr","plAno":"AltA CArDiológiCA, rEtorno ApEnAs sE sintomAs"}'),

('16E81A55-7410-4895-8B73-FAD28E8A1CF2', 'E7657BF8-9F97-4EF3-9FF3-48B02C2F8A52', 'E85FB568-4BFF-46C8-A772-713899DE38AA', '7E0B0170-DFAA-4C28-B743-AE21AD5C0D59', '2026-01-21', '14:00:00', '14:30:00', 0, 4, 'ControlE DM E HAS.', DAtEtimE('now'), DAtEtimE('now'),
'{"quEixAPrinCipAl":"ControlE DM/HAS","historiADoEnCAAtuAl":"ACompAnhAmEnto trimEstrAl"}',
'{"suBjEtivo":"GliCEmiAs Em jEjum 100-120, PA BEm ControlADA.","oBjEtivo":"PA: 126/80 mmHg, FC: 70 Bpm. HBA1C 6.8%, LDL 68.","AvAliACAo":"DM2 E HAS BEm ControlADos, mEtAs AtingiDAs","plAno":"MAntEr trAtAmEnto, pArABéns pElA ADEsão"}'),

('E1194F79-CA05-479C-A381-32615CAB4C57', '903F9074-FA7B-492E-A670-44C827B4CFDD', '03C7BB74-9BB2-48D6-8F6D-064376738F81', 'A0F4CDA0-6BF2-46E2-AB9F-15C72E137655', '2026-01-22', '10:00:00', '10:30:00', 0, 4, 'MElhorA signiFiCAtivA DEprEssão.', DAtEtimE('now'), DAtEtimE('now'),
'{"quEixAPrinCipAl":"MElhorA DEprEssão","historiADoEnCAAtuAl":"REtorno quinzEnAl"}',
'{"suBjEtivo":"MElhorA DE 70%. Voltou A sAir DE CAsA, rEtomou AtiviDADEs, sono normAlizADo.","oBjEtivo":"EutímiCA, sorriDEntE, BoA intErAção.","AvAliACAo":"DEprEssão Em FrAnCA rEmissão","plAno":"MAntEr VEnlAFAxinA 150mg E MirtAzApinA 15mg por 6 mEsEs"}'),

('19191513-7611-4B00-99E0-0AB4A1B67BA5', '71E0E646-73FA-4838-B73B-9E9C9CAAB4BA', '03C7BB74-9BB2-48D6-8F6D-064376738F81', 'A0F4CDA0-6BF2-46E2-AB9F-15C72E137655', '2026-01-23', '15:00:00', '15:30:00', 0, 4, 'SEguimEnto AnsiEDADE.', DAtEtimE('now'), DAtEtimE('now'),
'{"quEixAPrinCipAl":"SEguimEnto TAG","historiADoEnCAAtuAl":"REtorno mEnsAl"}',
'{"suBjEtivo":"AnsiEDADE ControlADA, DorminDo BEm, sEm CrisEs.","oBjEtivo":"CAlmo, sEm sinAis DE AnsiEDADE.","AvAliACAo":"TAG ControlADo","plAno":"MAntEr EsCitAloprAm 10mg, rEtorno Em 60 DiAs"}'),

('561F08B5-6DCD-47E4-BCA4-1F93FED65A9B', 'F764F4E1-E999-4254-9272-FB1BAD994E59', '03C7BB74-9BB2-48D6-8F6D-064376738F81', 'A0F4CDA0-6BF2-46E2-AB9F-15C72E137655', '2026-01-11', '16:00:00', '16:45:00', 0, 4, 'AvAliAção psiquiátriCA ComplEmEntAr.', DAtEtimE('now'), DAtEtimE('now'),
'{"quEixAPrinCipAl":"InsôniA CrôniCA","historiADoEnCAAtuAl":"EnCAminhADA pElo CArDiologistA por insôniA há Anos"}',
'{"suBjEtivo":"InsôniA iniCiAl há 5 Anos, DEmorA 1-2h pArA Dormir.","oBjEtivo":"Vigil, oriEntADA, humor EutímiCo, AnsiosA lEvE.","AvAliACAo":"InsôniA CrôniCA primáriA","plAno":"1. HigiEnE Do sono\n2. MElAtoninA 3mg\n3. REtorno Em 30 DiAs"}'),

('5D5ECF04-41D0-4613-8FF4-54343D54E654', 'AE637012-D984-4583-8824-3EABB5911886', 'E85FB568-4BFF-46C8-A772-713899DE38AA', '7E0B0170-DFAA-4C28-B743-AE21AD5C0D59', '2026-01-15', '08:00:00', '08:30:00', 0, 4, 'AvAliAção CArDiológiCA pré-ExErCíCio.', DAtEtimE('now'), DAtEtimE('now'),
'{"quEixAPrinCipAl":"LiBErAção pArA ACADEmiA","historiADoEnCAAtuAl":"QuEr iniCiAr musCulAção, ACADEmiA pEDiu AvAliAção"}',
'{"suBjEtivo":"JovEm sAuDávEl, quEr iniCiAr AtiviDADE FísiCA.","oBjEtivo":"PA: 118/72 mmHg, FC: 66 Bpm, AusCultA normAl, ECG normAl.","AvAliACAo":"Apto pArA AtiviDADE FísiCA sEm rEstriçõEs","plAno":"LiBErADo pArA musCulAção E AEróBiCos"}'),

('6ECACC73-9EC2-4B76-8948-3AC89714BC2C', 'BA040C1B-869F-4307-AA80-C6EFC83D95D1', '03C7BB74-9BB2-48D6-8F6D-064376738F81', 'A0F4CDA0-6BF2-46E2-AB9F-15C72E137655', '2026-01-18', '14:00:00', '14:30:00', 0, 4, 'AvAliAção AnsiEDADE gEstACionAl.', DAtEtimE('now'), DAtEtimE('now'),
'{"quEixAPrinCipAl":"AnsiEDADE nA gEstAção","historiADoEnCAAtuAl":"GEstAntE AnsiosA, prEoCupADA Com o pArto"}',
'{"suBjEtivo":"AnsiEDADE lEvE rElACionADA à gEstAção, mEDo Do pArto.","oBjEtivo":"AnsiosA lEvE, sEm Critérios pArA trAnstorno.","AvAliACAo":"AnsiEDADE situACionAl DA gEstAção","plAno":"1. PsiCotErApiA BrEvE\n2. TéCniCAs DE rElAxAmEnto\n3. REtorno sE piorAr"}'),

('CC3F489F-4531-4A0C-98D4-28D058C0E3FF', 'E7657BF8-9F97-4EF3-9FF3-48B02C2F8A52', '03C7BB74-9BB2-48D6-8F6D-064376738F81', 'A0F4CDA0-6BF2-46E2-AB9F-15C72E137655', '2026-01-19', '11:00:00', '11:30:00', 0, 4, 'RAstrEio DE DEprEssão Em DiABétiCo.', DAtEtimE('now'), DAtEtimE('now'),
'{"quEixAPrinCipAl":"RAstrEio DEprEssão","historiADoEnCAAtuAl":"EnCAminhADo pElo CArDiologistA pArA AvAliAr humor"}',
'{"suBjEtivo":"NEgA sintomAs DEprEssivos, Bom suportE FAmiliAr.","oBjEtivo":"EutímiCo, AFEto ADEquADo.","AvAliACAo":"SEm trAnstorno psiquiátriCo no momEnto","plAno":"Não nECEssitA ACompAnhAmEnto, rEtorno sE sintomAs"}'),

('FDF34B8F-EB30-49AE-A8D7-9E3DE132289B', '903F9074-FA7B-492E-A670-44C827B4CFDD', 'E85FB568-4BFF-46C8-A772-713899DE38AA', '7E0B0170-DFAA-4C28-B743-AE21AD5C0D59', '2026-01-20', '15:00:00', '15:30:00', 0, 4, 'AvAliAção CArDiológiCA Em DEprEssivA.', DAtEtimE('now'), DAtEtimE('now'),
'{"quEixAPrinCipAl":"PAlpitAçõEs","historiADoEnCAAtuAl":"PAlpitAçõEs DEsDE iníCio Do AntiDEprEssivo"}',
'{"suBjEtivo":"PAlpitAçõEs lEvEs Após iníCio DE VEnlAFAxinA.","oBjEtivo":"PA: 125/80 mmHg, FC: 86 Bpm, ritmo rEgulAr, ECG normAl.","AvAliACAo":"TAquiCArDiA sinusAl lEvE por VEnlAFAxinA, BEnignA","plAno":"TrAnquilizAr, EFEito EspErADo Do mEDiCAmEnto"}'),

('9BA1FF25-71CE-44BE-A18F-71ECA2E39282', '71E0E646-73FA-4838-B73B-9E9C9CAAB4BA', 'E85FB568-4BFF-46C8-A772-713899DE38AA', '7E0B0170-DFAA-4C28-B743-AE21AD5C0D59', '2025-12-15', '09:00:00', '09:30:00', 0, 4, 'ConsultA DE DEzEmBro - ChECk-up.', DAtEtimE('now'), DAtEtimE('now'),
'{"quEixAPrinCipAl":"ChECk-up AnuAl","historiADoEnCAAtuAl":"AvAliAção CArDiovAsCulAr DE rotinA"}',
'{"suBjEtivo":"SEm quEixAs, vEio pArA ChECk-up AnuAl.","oBjEtivo":"PA: 122/78, FC: 70, ExAmE normAl.","AvAliACAo":"SAuDávEl CArDiovAsCulArmEntE","plAno":"MAntEr háBitos sAuDávEis, rEtorno AnuAl"}'),

('9A876D14-92B1-4943-92B7-C0C08A01D923', 'F764F4E1-E999-4254-9272-FB1BAD994E59', 'E85FB568-4BFF-46C8-A772-713899DE38AA', '7E0B0170-DFAA-4C28-B743-AE21AD5C0D59', '2025-12-18', '10:00:00', '10:30:00', 0, 4, 'AjustE mEDiCAmEntoso HAS.', DAtEtimE('now'), DAtEtimE('now'),
'{"quEixAPrinCipAl":"PrEssão AltA","historiADoEnCAAtuAl":"PrEssão suBiu no Frio"}',
'{"suBjEtivo":"REFErE PA mAis AltA Em CAsA nAs últimAs sEmAnAs DE Frio.","oBjEtivo":"PA: 145/92 mmHg.","AvAliACAo":"DEsControlE prEssóriCo sAzonAl","plAno":"AumEntAr LosArtAnA DE 50 pArA 100mg"}'),

('0FBB3E67-D948-478F-99BB-4B42D1F86102', 'AE637012-D984-4583-8824-3EABB5911886', '03C7BB74-9BB2-48D6-8F6D-064376738F81', 'A0F4CDA0-6BF2-46E2-AB9F-15C72E137655', '2025-12-20', '15:00:00', '15:30:00', 0, 4, 'PrimEirA ConsultA DE DEzEmBro.', DAtEtimE('now'), DAtEtimE('now'),
'{"quEixAPrinCipAl":"IníCio trAtAmEnto","historiADoEnCAAtuAl":"PrimEirA AvAliAção Do trAnstorno DE pâniCo"}',
'{"suBjEtivo":"CrisEs DE pâniCo intEnsAs, primEirA vEz BusCAnDo trAtAmEnto.","oBjEtivo":"Muito Ansioso.","AvAliACAo":"TrAnstorno DE PâniCo","plAno":"IniCiAr SErtrAlinA E ACompAnhAmEnto"}'),

('C62C5612-05CC-437B-8A53-66A5D3C6A1F0', 'BA040C1B-869F-4307-AA80-C6EFC83D95D1', 'E85FB568-4BFF-46C8-A772-713899DE38AA', '7E0B0170-DFAA-4C28-B743-AE21AD5C0D59', '2025-12-22', '11:00:00', '11:30:00', 0, 4, 'PrimEirA ConsultA gEstAntE.', DAtEtimE('now'), DAtEtimE('now'),
'{"quEixAPrinCipAl":"AvAliAção gEstACionAl","historiADoEnCAAtuAl":"PrimEirA AvAliAção CArDiológiCA nA gEstAção"}',
'{"suBjEtivo":"GEstAntE 16 sEmAnAs, EnCAminhADA pArA AvAliAção DE sopro.","oBjEtivo":"Sopro inoCEntE.","AvAliACAo":"NormAl pArA gEstAção","plAno":"OriEntAçõEs E AltA"}'),

('6F65F999-198B-405E-834D-5036DED973AB', 'E7657BF8-9F97-4EF3-9FF3-48B02C2F8A52', 'E85FB568-4BFF-46C8-A772-713899DE38AA', '7E0B0170-DFAA-4C28-B743-AE21AD5C0D59', '2025-12-28', '14:00:00', '14:30:00', 0, 4, 'AvAliAção iniCiAl DiABétiCo.', DAtEtimE('now'), DAtEtimE('now'),
'{"quEixAPrinCipAl":"AvAliAção CArDiovAsCulAr","historiADoEnCAAtuAl":"DiABétiCo EnCAminhADo pArA AvAliAção DE risCo"}',
'{"suBjEtivo":"DM2 há 10 Anos, sEm AvAliAção CArDiológiCA préviA.","oBjEtivo":"PA lEvEmEntE ElEvADA.","AvAliACAo":"RisCo CArDiovAsCulAr moDErADo","plAno":"ExAmEs E rEtorno"}'),

('B12A0B5B-BFBF-4845-9F26-15B8557E139C', '903F9074-FA7B-492E-A670-44C827B4CFDD', '03C7BB74-9BB2-48D6-8F6D-064376738F81', 'A0F4CDA0-6BF2-46E2-AB9F-15C72E137655', '2025-12-30', '10:00:00', '10:45:00', 0, 4, 'PrimEirA ConsultA DEprEssão.', DAtEtimE('now'), DAtEtimE('now'),
'{"quEixAPrinCipAl":"DEprEssão grAvE","historiADoEnCAAtuAl":"ViúvA há 6 mEsEs, DEprEssão intEnsA"}',
'{"suBjEtivo":"TristEzA proFunDA, isolAmEnto, pErDA DE pEso, insôniA.","oBjEtivo":"Muito DEprimiDA.","AvAliACAo":"DEprEssão grAvE","plAno":"IniCiAr AntiDEprEssivos urgEntE"}');

-- ============================================================
-- CONSULTAS AGENDADAS (40) - StAtus 0 = SChEDulED
-- FEvErEiro E MArço DE 2026
-- ============================================================

INSERT INTO AppointmEnts (ID, PAtiEntID, ProFEssionAlID, SpECiAltyID, DAtE, TimE, EnDTimE, TypE, StAtus, CrEAtEDAt, UpDAtEDAt) VALUES
-- FEVEREIRO 2026 - SEmAnA 1
('7BF3B387-EEA2-4718-A856-619410E7025E', '71E0E646-73FA-4838-B73B-9E9C9CAAB4BA', 'E85FB568-4BFF-46C8-A772-713899DE38AA', '7E0B0170-DFAA-4C28-B743-AE21AD5C0D59', '2026-02-02', '09:00:00', '09:30:00', 0, 0, DAtEtimE('now'), DAtEtimE('now')),
('05C1D84F-DECF-4C8B-ACE6-0608FC203B02', 'F764F4E1-E999-4254-9272-FB1BAD994E59', 'E85FB568-4BFF-46C8-A772-713899DE38AA', '7E0B0170-DFAA-4C28-B743-AE21AD5C0D59', '2026-02-02', '10:00:00', '10:30:00', 0, 0, DAtEtimE('now'), DAtEtimE('now')),
('0B53E10D-BC57-478F-9190-31CDDE8DAB62', 'AE637012-D984-4583-8824-3EABB5911886', '03C7BB74-9BB2-48D6-8F6D-064376738F81', 'A0F4CDA0-6BF2-46E2-AB9F-15C72E137655', '2026-02-03', '14:00:00', '14:30:00', 0, 0, DAtEtimE('now'), DAtEtimE('now')),
('5DFE7A57-770F-4128-AD9D-A9FFB510A957', 'BA040C1B-869F-4307-AA80-C6EFC83D95D1', 'E85FB568-4BFF-46C8-A772-713899DE38AA', '7E0B0170-DFAA-4C28-B743-AE21AD5C0D59', '2026-02-03', '11:00:00', '11:30:00', 0, 0, DAtEtimE('now'), DAtEtimE('now')),
('4419B1C4-CF16-4805-8ECC-902000615462', 'E7657BF8-9F97-4EF3-9FF3-48B02C2F8A52', 'E85FB568-4BFF-46C8-A772-713899DE38AA', '7E0B0170-DFAA-4C28-B743-AE21AD5C0D59', '2026-02-04', '08:30:00', '09:00:00', 0, 0, DAtEtimE('now'), DAtEtimE('now')),
('F3CF97F7-D3EE-4FDC-8D7D-21AD9BFF3AA3', '903F9074-FA7B-492E-A670-44C827B4CFDD', '03C7BB74-9BB2-48D6-8F6D-064376738F81', 'A0F4CDA0-6BF2-46E2-AB9F-15C72E137655', '2026-02-04', '10:00:00', '10:30:00', 0, 0, DAtEtimE('now'), DAtEtimE('now')),
('BB64ACC7-5E6D-43D1-B2FA-51EBF2F7BE0D', '71E0E646-73FA-4838-B73B-9E9C9CAAB4BA', '03C7BB74-9BB2-48D6-8F6D-064376738F81', 'A0F4CDA0-6BF2-46E2-AB9F-15C72E137655', '2026-02-05', '15:00:00', '15:30:00', 0, 0, DAtEtimE('now'), DAtEtimE('now')),
('E6C6EF68-8015-419E-801A-274EB256CD38', 'F764F4E1-E999-4254-9272-FB1BAD994E59', '03C7BB74-9BB2-48D6-8F6D-064376738F81', 'A0F4CDA0-6BF2-46E2-AB9F-15C72E137655', '2026-02-05', '16:00:00', '16:30:00', 0, 0, DAtEtimE('now'), DAtEtimE('now'));

-- GErAr mAis 32 ConsultAs AgEnDADAs
INSERT INTO AppointmEnts (ID, PAtiEntID, ProFEssionAlID, SpECiAltyID, DAtE, TimE, EnDTimE, TypE, StAtus, CrEAtEDAt, UpDAtEDAt) VALUES
('5B5E0A35-3CA7-418C-97E8-7D08C595EE3D', 'AE637012-D984-4583-8824-3EABB5911886', 'E85FB568-4BFF-46C8-A772-713899DE38AA', '7E0B0170-DFAA-4C28-B743-AE21AD5C0D59', '2026-02-09', '09:00:00', '09:30:00', 0, 0, DAtEtimE('now'), DAtEtimE('now')),
('831D1CD1-CD02-427A-A6EB-C60E1B197E58', 'BA040C1B-869F-4307-AA80-C6EFC83D95D1', '03C7BB74-9BB2-48D6-8F6D-064376738F81', 'A0F4CDA0-6BF2-46E2-AB9F-15C72E137655', '2026-02-09', '14:00:00', '14:30:00', 0, 0, DAtEtimE('now'), DAtEtimE('now')),
('7BB300AC-0C54-4961-8E80-5A58FF7174E4', 'E7657BF8-9F97-4EF3-9FF3-48B02C2F8A52', '03C7BB74-9BB2-48D6-8F6D-064376738F81', 'A0F4CDA0-6BF2-46E2-AB9F-15C72E137655', '2026-02-10', '10:00:00', '10:30:00', 0, 0, DAtEtimE('now'), DAtEtimE('now')),
('162C4C74-183F-40F9-B0DC-BCF1195BFC8E', '903F9074-FA7B-492E-A670-44C827B4CFDD', 'E85FB568-4BFF-46C8-A772-713899DE38AA', '7E0B0170-DFAA-4C28-B743-AE21AD5C0D59', '2026-02-10', '15:00:00', '15:30:00', 0, 0, DAtEtimE('now'), DAtEtimE('now')),
('8E15DA52-D402-49CF-88E2-3A7A887C5C5D', '71E0E646-73FA-4838-B73B-9E9C9CAAB4BA', 'E85FB568-4BFF-46C8-A772-713899DE38AA', '7E0B0170-DFAA-4C28-B743-AE21AD5C0D59', '2026-02-16', '08:00:00', '08:30:00', 0, 0, DAtEtimE('now'), DAtEtimE('now')),
('6C30BCAA-42CC-428C-8B99-D27F498F1178', 'F764F4E1-E999-4254-9272-FB1BAD994E59', 'E85FB568-4BFF-46C8-A772-713899DE38AA', '7E0B0170-DFAA-4C28-B743-AE21AD5C0D59', '2026-02-17', '09:00:00', '09:30:00', 0, 0, DAtEtimE('now'), DAtEtimE('now')),
('AD5E59BC-235B-42C0-ACCD-848748A2C3DB', 'AE637012-D984-4583-8824-3EABB5911886', '03C7BB74-9BB2-48D6-8F6D-064376738F81', 'A0F4CDA0-6BF2-46E2-AB9F-15C72E137655', '2026-02-18', '14:00:00', '14:30:00', 0, 0, DAtEtimE('now'), DAtEtimE('now')),
('2BFB1A24-5709-4FBF-8108-06447C8006CD', 'BA040C1B-869F-4307-AA80-C6EFC83D95D1', 'E85FB568-4BFF-46C8-A772-713899DE38AA', '7E0B0170-DFAA-4C28-B743-AE21AD5C0D59', '2026-02-19', '10:00:00', '10:30:00', 0, 0, DAtEtimE('now'), DAtEtimE('now')),
('E563C87F-EE58-4F32-BE39-4E3B2FC3CE3B', 'E7657BF8-9F97-4EF3-9FF3-48B02C2F8A52', 'E85FB568-4BFF-46C8-A772-713899DE38AA', '7E0B0170-DFAA-4C28-B743-AE21AD5C0D59', '2026-02-23', '11:00:00', '11:30:00', 0, 0, DAtEtimE('now'), DAtEtimE('now')),
('3CE917A8-5EDF-4A03-BD72-8CB46D3050FB', '903F9074-FA7B-492E-A670-44C827B4CFDD', '03C7BB74-9BB2-48D6-8F6D-064376738F81', 'A0F4CDA0-6BF2-46E2-AB9F-15C72E137655', '2026-02-24', '15:00:00', '15:30:00', 0, 0, DAtEtimE('now'), DAtEtimE('now')),
('9C6B917E-BB57-40A4-A9F4-584EF0DF5E34', '71E0E646-73FA-4838-B73B-9E9C9CAAB4BA', '03C7BB74-9BB2-48D6-8F6D-064376738F81', 'A0F4CDA0-6BF2-46E2-AB9F-15C72E137655', '2026-02-25', '09:00:00', '09:30:00', 0, 0, DAtEtimE('now'), DAtEtimE('now')),
('FADE835C-8ABF-4DD4-B6A9-CB178105491C', 'F764F4E1-E999-4254-9272-FB1BAD994E59', '03C7BB74-9BB2-48D6-8F6D-064376738F81', 'A0F4CDA0-6BF2-46E2-AB9F-15C72E137655', '2026-02-26', '14:00:00', '14:30:00', 0, 0, DAtEtimE('now'), DAtEtimE('now')),

-- MARÇO 2026
('373C31E0-DC1E-48AC-9CBB-9859D8F7E401', 'AE637012-D984-4583-8824-3EABB5911886', 'E85FB568-4BFF-46C8-A772-713899DE38AA', '7E0B0170-DFAA-4C28-B743-AE21AD5C0D59', '2026-03-02', '08:00:00', '08:30:00', 0, 0, DAtEtimE('now'), DAtEtimE('now')),
('D42B6E40-509C-4048-A44E-C57B5082340A', 'BA040C1B-869F-4307-AA80-C6EFC83D95D1', '03C7BB74-9BB2-48D6-8F6D-064376738F81', 'A0F4CDA0-6BF2-46E2-AB9F-15C72E137655', '2026-03-02', '10:00:00', '10:30:00', 0, 0, DAtEtimE('now'), DAtEtimE('now')),
('4780B0BD-E394-4579-9219-B53FD6D377D5', 'E7657BF8-9F97-4EF3-9FF3-48B02C2F8A52', '03C7BB74-9BB2-48D6-8F6D-064376738F81', 'A0F4CDA0-6BF2-46E2-AB9F-15C72E137655', '2026-03-03', '15:00:00', '15:30:00', 0, 0, DAtEtimE('now'), DAtEtimE('now')),
('75CB5EC6-925B-41F7-9C12-280A77D54E02', '903F9074-FA7B-492E-A670-44C827B4CFDD', 'E85FB568-4BFF-46C8-A772-713899DE38AA', '7E0B0170-DFAA-4C28-B743-AE21AD5C0D59', '2026-03-03', '09:00:00', '09:30:00', 0, 0, DAtEtimE('now'), DAtEtimE('now')),
('FB930203-E186-4B28-8571-9262DDC27190', '71E0E646-73FA-4838-B73B-9E9C9CAAB4BA', 'E85FB568-4BFF-46C8-A772-713899DE38AA', '7E0B0170-DFAA-4C28-B743-AE21AD5C0D59', '2026-03-04', '11:00:00', '11:30:00', 0, 0, DAtEtimE('now'), DAtEtimE('now')),
('24F78DC6-1837-437E-B242-7B8E469EA915', 'F764F4E1-E999-4254-9272-FB1BAD994E59', 'E85FB568-4BFF-46C8-A772-713899DE38AA', '7E0B0170-DFAA-4C28-B743-AE21AD5C0D59', '2026-03-05', '14:00:00', '14:30:00', 0, 0, DAtEtimE('now'), DAtEtimE('now')),
('52B4CE79-8584-4FC0-8512-0F602B73C985', 'AE637012-D984-4583-8824-3EABB5911886', '03C7BB74-9BB2-48D6-8F6D-064376738F81', 'A0F4CDA0-6BF2-46E2-AB9F-15C72E137655', '2026-03-09', '09:00:00', '09:30:00', 0, 0, DAtEtimE('now'), DAtEtimE('now')),
('27AFC103-D522-4675-9F08-03E49C01142B', 'BA040C1B-869F-4307-AA80-C6EFC83D95D1', 'E85FB568-4BFF-46C8-A772-713899DE38AA', '7E0B0170-DFAA-4C28-B743-AE21AD5C0D59', '2026-03-10', '10:00:00', '10:30:00', 0, 0, DAtEtimE('now'), DAtEtimE('now')),
('4AE22444-56C5-4391-AE1D-B6E92844193D', 'E7657BF8-9F97-4EF3-9FF3-48B02C2F8A52', 'E85FB568-4BFF-46C8-A772-713899DE38AA', '7E0B0170-DFAA-4C28-B743-AE21AD5C0D59', '2026-03-11', '08:30:00', '09:00:00', 0, 0, DAtEtimE('now'), DAtEtimE('now')),
('C5E2818E-B8AA-44FE-9A5A-C0158CC8F5C4', '903F9074-FA7B-492E-A670-44C827B4CFDD', '03C7BB74-9BB2-48D6-8F6D-064376738F81', 'A0F4CDA0-6BF2-46E2-AB9F-15C72E137655', '2026-03-12', '15:00:00', '15:30:00', 0, 0, DAtEtimE('now'), DAtEtimE('now')),
('C660C9E9-402E-41A7-BA2E-F1FBCD7111E1', '71E0E646-73FA-4838-B73B-9E9C9CAAB4BA', '03C7BB74-9BB2-48D6-8F6D-064376738F81', 'A0F4CDA0-6BF2-46E2-AB9F-15C72E137655', '2026-03-16', '14:00:00', '14:30:00', 0, 0, DAtEtimE('now'), DAtEtimE('now')),
('2AE2BD4F-F43D-4158-85ED-387A09E0D59B', 'F764F4E1-E999-4254-9272-FB1BAD994E59', '03C7BB74-9BB2-48D6-8F6D-064376738F81', 'A0F4CDA0-6BF2-46E2-AB9F-15C72E137655', '2026-03-17', '10:00:00', '10:30:00', 0, 0, DAtEtimE('now'), DAtEtimE('now')),
('3A7D9A9B-04A9-40F9-9E58-3AF461F532FB', 'AE637012-D984-4583-8824-3EABB5911886', 'E85FB568-4BFF-46C8-A772-713899DE38AA', '7E0B0170-DFAA-4C28-B743-AE21AD5C0D59', '2026-03-18', '09:00:00', '09:30:00', 0, 0, DAtEtimE('now'), DAtEtimE('now')),
('A88AD97F-A0C7-4006-BD73-ACF31387431E', 'BA040C1B-869F-4307-AA80-C6EFC83D95D1', 'E85FB568-4BFF-46C8-A772-713899DE38AA', '7E0B0170-DFAA-4C28-B743-AE21AD5C0D59', '2026-03-19', '11:00:00', '11:30:00', 0, 0, DAtEtimE('now'), DAtEtimE('now')),
('22C1758E-751C-47A8-B322-8368B09BD6B4', 'E7657BF8-9F97-4EF3-9FF3-48B02C2F8A52', '03C7BB74-9BB2-48D6-8F6D-064376738F81', 'A0F4CDA0-6BF2-46E2-AB9F-15C72E137655', '2026-03-23', '15:00:00', '15:30:00', 0, 0, DAtEtimE('now'), DAtEtimE('now')),
('15DA9D4D-A6C5-4884-B1C3-ED042921926D', '903F9074-FA7B-492E-A670-44C827B4CFDD', 'E85FB568-4BFF-46C8-A772-713899DE38AA', '7E0B0170-DFAA-4C28-B743-AE21AD5C0D59', '2026-03-24', '08:00:00', '08:30:00', 0, 0, DAtEtimE('now'), DAtEtimE('now')),
('52E7626E-3C79-47FE-99D8-FB87B551DA5F', '71E0E646-73FA-4838-B73B-9E9C9CAAB4BA', 'E85FB568-4BFF-46C8-A772-713899DE38AA', '7E0B0170-DFAA-4C28-B743-AE21AD5C0D59', '2026-03-25', '10:00:00', '10:30:00', 0, 0, DAtEtimE('now'), DAtEtimE('now')),
('C4F55712-CD54-4879-B223-2D19C50A71C6', 'F764F4E1-E999-4254-9272-FB1BAD994E59', 'E85FB568-4BFF-46C8-A772-713899DE38AA', '7E0B0170-DFAA-4C28-B743-AE21AD5C0D59', '2026-03-26', '14:00:00', '14:30:00', 0, 0, DAtEtimE('now'), DAtEtimE('now')),
('88B5B102-7CE8-4234-9787-DAA555E03F6C', 'AE637012-D984-4583-8824-3EABB5911886', '03C7BB74-9BB2-48D6-8F6D-064376738F81', 'A0F4CDA0-6BF2-46E2-AB9F-15C72E137655', '2026-03-30', '09:00:00', '09:30:00', 0, 0, DAtEtimE('now'), DAtEtimE('now')),
('62734EF5-C2AF-40F1-8726-099932DA0240', 'BA040C1B-869F-4307-AA80-C6EFC83D95D1', '03C7BB74-9BB2-48D6-8F6D-064376738F81', 'A0F4CDA0-6BF2-46E2-AB9F-15C72E137655', '2026-03-31', '14:00:00', '14:30:00', 0, 0, DAtEtimE('now'), DAtEtimE('now'));

-- ============================================================
-- FIM DO SCRIPT
-- ============================================================
