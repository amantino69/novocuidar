--
-- PostgreSQL database dump
--

\restrict Lb5oeHjrGor3NPItVLgSjDPQeghUJtG7WFde2tf7O780U2EL2eC8MihePQukwqW

-- Dumped from database version 16.11 (Debian 16.11-1.pgdg13+1)
-- Dumped by pg_dump version 16.11 (Debian 16.11-1.pgdg13+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: Appointments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Appointments" (
    "Id" text NOT NULL,
    "PatientId" text NOT NULL,
    "ProfessionalId" text NOT NULL,
    "SpecialtyId" text NOT NULL,
    "Date" text NOT NULL,
    "Time" text NOT NULL,
    "EndTime" text,
    "Type" integer NOT NULL,
    "Status" integer NOT NULL,
    "Observation" text,
    "MeetLink" text,
    "PreConsultationJson" text,
    "BiometricsJson" text,
    "AttachmentsChatJson" text,
    "AnamnesisJson" text,
    "SoapJson" text,
    "SpecialtyFieldsJson" text,
    "AISummary" text,
    "AISummaryGeneratedAt" text,
    "AIDiagnosticHypothesis" text,
    "AIDiagnosisGeneratedAt" text,
    "CreatedAt" text NOT NULL,
    "UpdatedAt" text NOT NULL,
    "AssistantId" text,
    "CheckInTime" text,
    "ConsultationStartedAt" text,
    "DoctorJoinedAt" text,
    "ConsultationEndedAt" text,
    "DurationInMinutes" integer,
    "NotificationsSentCount" integer DEFAULT 0,
    "LastNotificationSentAt" text,
    "LastActivityAt" text,
    "SpontaneousDemand" integer DEFAULT 0,
    "UrgencyLevel" integer DEFAULT 0,
    "PositionInQueue" integer,
    "TriageNotes" text,
    "ReasonForVisit" text
);


--
-- Name: Attachments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Attachments" (
    "Id" text NOT NULL,
    "AppointmentId" text NOT NULL,
    "Title" text NOT NULL,
    "FileName" text NOT NULL,
    "FilePath" text NOT NULL,
    "FileType" text NOT NULL,
    "FileSize" integer NOT NULL,
    "CreatedAt" text NOT NULL,
    "UpdatedAt" text NOT NULL
);


--
-- Name: AuditLogs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."AuditLogs" (
    "Id" text NOT NULL,
    "UserId" text,
    "Action" text NOT NULL,
    "EntityType" text NOT NULL,
    "EntityId" text NOT NULL,
    "OldValues" text,
    "NewValues" text,
    "IpAddress" text,
    "UserAgent" text,
    "CreatedAt" text NOT NULL,
    "UpdatedAt" text NOT NULL,
    "AccessReason" text,
    "DataCategory" text,
    "PatientCpf" text,
    "PatientId" text
);


--
-- Name: CboOccupations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."CboOccupations" (
    "Id" text NOT NULL,
    "Code" text NOT NULL,
    "Name" text NOT NULL,
    "Family" text,
    "Subgroup" text,
    "AllowsTeleconsultation" integer NOT NULL,
    "IsActive" integer NOT NULL,
    "CreatedAt" text NOT NULL,
    "UpdatedAt" text NOT NULL
);


--
-- Name: DigitalCertificates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."DigitalCertificates" (
    "Id" text NOT NULL,
    "UserId" text NOT NULL,
    "DisplayName" text NOT NULL,
    "Subject" text NOT NULL,
    "Issuer" text NOT NULL,
    "Thumbprint" text NOT NULL,
    "CpfFromCertificate" text,
    "NameFromCertificate" text,
    "ExpirationDate" text NOT NULL,
    "IssuedDate" text NOT NULL,
    "EncryptedPfxBase64" text NOT NULL,
    "QuickUseEnabled" integer NOT NULL,
    "EncryptedPassword" text,
    "EncryptionIV" text NOT NULL,
    "IsActive" integer NOT NULL,
    "LastUsedAt" text,
    "CreatedAt" text NOT NULL,
    "UpdatedAt" text NOT NULL
);


--
-- Name: ExamRequests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."ExamRequests" (
    "Id" text NOT NULL,
    "AppointmentId" text NOT NULL,
    "ProfessionalId" text NOT NULL,
    "PatientId" text NOT NULL,
    "NomeExame" text NOT NULL,
    "CodigoExame" text,
    "Categoria" integer NOT NULL,
    "Prioridade" integer NOT NULL,
    "DataEmissao" text NOT NULL,
    "DataLimite" text,
    "IndicacaoClinica" text NOT NULL,
    "HipoteseDiagnostica" text,
    "Cid" text,
    "Observacoes" text,
    "InstrucoesPreparo" text,
    "DigitalSignature" text,
    "CertificateThumbprint" text,
    "CertificateSubject" text,
    "SignedAt" text,
    "DocumentHash" text,
    "SignedPdfBase64" text,
    "CreatedAt" text NOT NULL,
    "UpdatedAt" text NOT NULL
);


--
-- Name: Invites; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Invites" (
    "Id" text NOT NULL,
    "Email" text,
    "Role" integer NOT NULL,
    "SpecialtyId" text,
    "Token" text NOT NULL,
    "Status" integer NOT NULL,
    "ExpiresAt" text NOT NULL,
    "CreatedBy" text NOT NULL,
    "CreatedAt" text NOT NULL,
    "AcceptedAt" text,
    "PrefilledName" text,
    "PrefilledLastName" text,
    "PrefilledCpf" text,
    "PrefilledPhone" text
);


--
-- Name: MedicalCertificates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."MedicalCertificates" (
    "Id" text NOT NULL,
    "AppointmentId" text NOT NULL,
    "ProfessionalId" text NOT NULL,
    "PatientId" text NOT NULL,
    "Tipo" integer NOT NULL,
    "DataEmissao" text NOT NULL,
    "DataInicio" text,
    "DataFim" text,
    "DiasAfastamento" integer,
    "Cid" text,
    "Conteudo" text NOT NULL,
    "Observacoes" text,
    "DigitalSignature" text,
    "CertificateThumbprint" text,
    "CertificateSubject" text,
    "SignedAt" text,
    "DocumentHash" text,
    "SignedPdfBase64" text,
    "CreatedAt" text NOT NULL,
    "UpdatedAt" text NOT NULL
);


--
-- Name: MedicalReports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."MedicalReports" (
    "Id" text NOT NULL,
    "AppointmentId" text NOT NULL,
    "ProfessionalId" text NOT NULL,
    "PatientId" text NOT NULL,
    "Tipo" integer NOT NULL,
    "Titulo" text NOT NULL,
    "DataEmissao" text NOT NULL,
    "HistoricoClinico" text,
    "ExameFisico" text,
    "ExamesComplementares" text,
    "HipoteseDiagnostica" text,
    "Cid" text,
    "Conclusao" text NOT NULL,
    "Recomendacoes" text,
    "Observacoes" text,
    "DigitalSignature" text,
    "CertificateThumbprint" text,
    "CertificateSubject" text,
    "SignedAt" text,
    "DocumentHash" text,
    "SignedPdfBase64" text,
    "CreatedAt" text NOT NULL,
    "UpdatedAt" text NOT NULL
);


--
-- Name: Notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Notifications" (
    "Id" text NOT NULL,
    "UserId" text NOT NULL,
    "Title" text NOT NULL,
    "Message" text NOT NULL,
    "Type" text NOT NULL,
    "IsRead" integer NOT NULL,
    "Link" text,
    "CreatedAt" text NOT NULL,
    "UpdatedAt" text NOT NULL
);


--
-- Name: PatientProfiles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."PatientProfiles" (
    "Id" text NOT NULL,
    "UserId" text NOT NULL,
    "Cns" text,
    "SocialName" text,
    "Gender" text,
    "BirthDate" text,
    "MotherName" text,
    "FatherName" text,
    "Nationality" text,
    "ZipCode" text,
    "Address" text,
    "City" text,
    "State" text,
    "CreatedAt" text NOT NULL,
    "UpdatedAt" text NOT NULL
);


--
-- Name: Prescriptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Prescriptions" (
    "Id" text NOT NULL,
    "AppointmentId" text NOT NULL,
    "ProfessionalId" text NOT NULL,
    "PatientId" text NOT NULL,
    "ItemsJson" text NOT NULL,
    "DigitalSignature" text,
    "CertificateThumbprint" text,
    "CertificateSubject" text,
    "SignedAt" text,
    "DocumentHash" text,
    "SignedPdfBase64" text,
    "CreatedAt" text NOT NULL,
    "UpdatedAt" text NOT NULL
);


--
-- Name: ProfessionalCouncils; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."ProfessionalCouncils" (
    "Id" text NOT NULL,
    "Acronym" text NOT NULL,
    "Name" text NOT NULL,
    "Category" text NOT NULL,
    "IsActive" integer NOT NULL,
    "CreatedAt" text NOT NULL,
    "UpdatedAt" text NOT NULL
);


--
-- Name: ProfessionalProfiles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."ProfessionalProfiles" (
    "Id" text NOT NULL,
    "UserId" text NOT NULL,
    "Crm" text,
    "Cbo" text,
    "SpecialtyId" text,
    "Gender" text,
    "BirthDate" text,
    "Nationality" text,
    "ZipCode" text,
    "Address" text,
    "City" text,
    "State" text,
    "CreatedAt" text NOT NULL,
    "UpdatedAt" text NOT NULL,
    "CboOccupationId" text,
    "CouncilId" text,
    "CouncilRegistration" text,
    "CouncilState" text
);


--
-- Name: ScheduleBlocks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."ScheduleBlocks" (
    "Id" text NOT NULL,
    "ProfessionalId" text NOT NULL,
    "Type" integer NOT NULL,
    "Date" text,
    "StartDate" text,
    "EndDate" text,
    "Reason" text NOT NULL,
    "Status" integer NOT NULL,
    "ApprovedBy" text,
    "ApprovedAt" text,
    "RejectionReason" text,
    "CreatedAt" text NOT NULL,
    "UpdatedAt" text NOT NULL
);


--
-- Name: Schedules; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Schedules" (
    "Id" text NOT NULL,
    "ProfessionalId" text NOT NULL,
    "GlobalConfigJson" text NOT NULL,
    "DaysConfigJson" text NOT NULL,
    "ValidityStartDate" text NOT NULL,
    "ValidityEndDate" text,
    "IsActive" integer NOT NULL,
    "CreatedAt" text NOT NULL,
    "UpdatedAt" text NOT NULL
);


--
-- Name: SigtapProcedures; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."SigtapProcedures" (
    "Id" text NOT NULL,
    "Code" text NOT NULL,
    "Name" text NOT NULL,
    "Description" text,
    "Complexity" integer NOT NULL,
    "GroupCode" text,
    "GroupName" text,
    "SubgroupCode" text,
    "SubgroupName" text,
    "AuthorizedCbosJson" text,
    "Value" text,
    "AllowsTelemedicine" integer NOT NULL,
    "IsActive" integer NOT NULL,
    "StartCompetency" text,
    "EndCompetency" text,
    "CreatedAt" text NOT NULL,
    "UpdatedAt" text NOT NULL
);


--
-- Name: Specialties; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Specialties" (
    "Id" text NOT NULL,
    "Name" text NOT NULL,
    "Description" text NOT NULL,
    "Status" integer NOT NULL,
    "CustomFieldsJson" text,
    "CreatedAt" text NOT NULL,
    "UpdatedAt" text NOT NULL
);


--
-- Name: Users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Users" (
    "Id" text NOT NULL,
    "Email" text NOT NULL,
    "PasswordHash" text NOT NULL,
    "Name" text NOT NULL,
    "LastName" text NOT NULL,
    "Cpf" text NOT NULL,
    "Phone" text,
    "Avatar" text,
    "Role" integer NOT NULL,
    "Status" integer NOT NULL,
    "EmailVerified" integer NOT NULL,
    "EmailVerificationToken" text,
    "EmailVerificationTokenExpiry" text,
    "PendingEmail" text,
    "PendingEmailToken" text,
    "PendingEmailTokenExpiry" text,
    "PasswordResetToken" text,
    "PasswordResetTokenExpiry" text,
    "RefreshToken" text,
    "RefreshTokenExpiry" text,
    "CreatedAt" text NOT NULL,
    "UpdatedAt" text NOT NULL
);


--
-- Name: __EFMigrationsHistory; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."__EFMigrationsHistory" (
    "MigrationId" character varying(150) NOT NULL,
    "ProductVersion" character varying(32) NOT NULL
);


--
-- Data for Name: Appointments; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."Appointments" ("Id", "PatientId", "ProfessionalId", "SpecialtyId", "Date", "Time", "EndTime", "Type", "Status", "Observation", "MeetLink", "PreConsultationJson", "BiometricsJson", "AttachmentsChatJson", "AnamnesisJson", "SoapJson", "SpecialtyFieldsJson", "AISummary", "AISummaryGeneratedAt", "AIDiagnosticHypothesis", "AIDiagnosisGeneratedAt", "CreatedAt", "UpdatedAt", "AssistantId", "CheckInTime", "ConsultationStartedAt", "DoctorJoinedAt", "ConsultationEndedAt", "DurationInMinutes", "NotificationsSentCount", "LastNotificationSentAt", "LastActivityAt", "SpontaneousDemand", "UrgencyLevel", "PositionInQueue", "TriageNotes", "ReasonForVisit") FROM stdin;
01bfdf37-18da-474c-b0a2-dc7fa2158065	268323db-7e11-42d4-85ee-7d4337798131	09c33afc-d053-4f1d-946d-aba173642b36	8ee8d058-d70b-4bd0-916f-5dbe9621caf5	2026-02-03T00:00:00.0000000	14:00:00	14:30:00	0	0	Consulta de primeira vez - POC TeleCuidar	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-02-05T10:29:26.7500430Z	2026-02-05T10:29:26.7500432Z	\N	\N	\N	\N	\N	\N	0	\N	\N	0	0	\N	\N	\N
01e4661a-a37d-48e7-8653-223353635b92	1a25bc58-0f72-4f59-a892-0d6ee51f0c07	c8d3e9ae-1b97-4758-8789-5ef40dd70abb	5b4fc232-61f3-4066-912d-d9367d818798	2026-02-03T00:00:00.0000000	11:00:00	11:30:00	2	0	Consulta de retorno - POC TeleCuidar	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-02-05T10:29:26.7472880Z	2026-02-05T10:29:26.7472881Z	\N	\N	\N	\N	\N	\N	0	\N	\N	0	0	\N	\N	\N
0834c2a5-edf2-48ef-8f48-bf32b70bcc66	1a25bc58-0f72-4f59-a892-0d6ee51f0c07	321c02a6-3abb-4158-93e9-41ce25573586	ae03858a-9cb0-4361-8857-857435949d82	2026-02-03T00:00:00.0000000	16:00:00	16:30:00	4	0	Consulta de retorno - POC TeleCuidar	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-02-05T10:29:26.7530036Z	2026-02-05T10:29:26.7530037Z	\N	\N	\N	\N	\N	\N	0	\N	\N	0	0	\N	\N	\N
20ccea1e-8f83-4037-9aba-6b0bbeadeca1	62f70bc8-e96e-4308-bffc-15bcada66ed7	f7fa3199-a452-4244-aabd-4fff524edbd8	a3e0437e-76c6-478a-a465-1d1b81e8bbb9	2026-02-10T00:00:00.0000000	16:30:00	17:00:00	1	0	Consulta de retorno - POC TeleCuidar	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-02-05T10:29:26.7553103Z	2026-02-05T10:29:26.7553104Z	\N	\N	\N	\N	\N	\N	0	\N	\N	0	0	\N	\N	\N
25a4072a-1755-4d92-8cdc-34f214de61a5	1a25bc58-0f72-4f59-a892-0d6ee51f0c07	321c02a6-3abb-4158-93e9-41ce25573586	ae03858a-9cb0-4361-8857-857435949d82	2026-02-03T00:00:00.0000000	16:00:00	16:30:00	4	6	Consulta de retorno - POC TeleCuidar	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-02-05T10:29:26.7531654Z	2026-02-05T10:29:26.7531655Z	\N	\N	\N	\N	\N	\N	0	\N	\N	0	0	\N	\N	\N
27e014b4-d63e-46f0-bf5d-5b67841ef06a	1b136568-233e-4201-9c43-f0445a6017b3	321c02a6-3abb-4158-93e9-41ce25573586	ae03858a-9cb0-4361-8857-857435949d82	2026-02-04T00:00:00.0000000	09:00:00	09:30:00	0	0	Consulta de primeira vez - POC TeleCuidar	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-02-05T10:29:26.7535833Z	2026-02-05T10:29:26.7535834Z	\N	\N	\N	\N	\N	\N	0	\N	\N	0	0	\N	\N	\N
2b3280b9-04e3-4e56-a86c-cb0238c24d5e	1b136568-233e-4201-9c43-f0445a6017b3	c8d3e9ae-1b97-4758-8789-5ef40dd70abb	5b4fc232-61f3-4066-912d-d9367d818798	2026-02-03T00:00:00.0000000	16:30:00	17:00:00	2	0	Consulta de retorno - POC TeleCuidar	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-02-05T10:29:26.7474085Z	2026-02-05T10:29:26.7474086Z	\N	\N	\N	\N	\N	\N	0	\N	\N	0	0	\N	\N	\N
2c991c35-5469-416f-a659-cee626aaccf0	1a25bc58-0f72-4f59-a892-0d6ee51f0c07	dc42f275-da07-437e-9c47-32100563d610	f5196497-9f26-4f98-a240-1bb0c8c60639	2026-02-04T00:00:00.0000000	08:00:00	08:30:00	2	1	Consulta de retorno - POC TeleCuidar	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-02-05T10:29:26.7486799Z	2026-02-05T10:29:26.7486800Z	\N	\N	\N	\N	\N	\N	0	\N	\N	0	0	\N	\N	\N
3175a987-11bd-4336-a617-ec405192e667	268323db-7e11-42d4-85ee-7d4337798131	f7fa3199-a452-4244-aabd-4fff524edbd8	a3e0437e-76c6-478a-a465-1d1b81e8bbb9	2026-02-02T00:00:00.0000000	13:30:00	14:00:00	0	1	Consulta de primeira vez - POC TeleCuidar	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-02-05T10:29:26.7543155Z	2026-02-05T10:29:26.7543157Z	\N	\N	\N	\N	\N	\N	0	\N	\N	0	0	\N	\N	\N
32aca77b-1810-4bb5-b847-6babee3c6c80	268323db-7e11-42d4-85ee-7d4337798131	f7fa3199-a452-4244-aabd-4fff524edbd8	a3e0437e-76c6-478a-a465-1d1b81e8bbb9	2026-02-03T00:00:00.0000000	13:00:00	13:30:00	1	1	Consulta de retorno - POC TeleCuidar	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-02-05T10:29:26.7544858Z	2026-02-05T10:29:26.7544859Z	\N	\N	\N	\N	\N	\N	0	\N	\N	0	0	\N	\N	\N
3a37154b-de29-4936-9f6b-772e72cff91d	454458dd-c79a-4fe1-8d7c-2e5d712ee871	09c33afc-d053-4f1d-946d-aba173642b36	8ee8d058-d70b-4bd0-916f-5dbe9621caf5	2026-02-03T00:00:00.0000000	12:30:00	13:00:00	1	1	Consulta de retorno - POC TeleCuidar	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-02-05T10:29:26.7505069Z	2026-02-05T10:29:26.7505074Z	\N	\N	\N	\N	\N	\N	0	\N	\N	0	0	\N	\N	\N
45ad257f-f475-435a-a490-74bd695d5148	1b136568-233e-4201-9c43-f0445a6017b3	c8d3e9ae-1b97-4758-8789-5ef40dd70abb	5b4fc232-61f3-4066-912d-d9367d818798	2026-02-04T00:00:00.0000000	09:30:00	10:00:00	2	1	Consulta de retorno - POC TeleCuidar	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-02-05T10:29:26.7475135Z	2026-02-05T10:29:26.7475136Z	\N	\N	\N	\N	\N	\N	0	\N	\N	0	0	\N	\N	\N
4a8b9ff0-5805-4bc6-894e-9e0196ce8522	268323db-7e11-42d4-85ee-7d4337798131	c8d3e9ae-1b97-4758-8789-5ef40dd70abb	5b4fc232-61f3-4066-912d-d9367d818798	2026-02-02T00:00:00.0000000	14:00:00	14:30:00	2	0	Consulta de retorno - POC TeleCuidar	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-02-05T10:29:26.7443638Z	2026-02-05T10:29:26.7443642Z	\N	\N	\N	\N	\N	\N	0	\N	\N	0	0	\N	\N	\N
58264a0f-19f2-47e8-9ded-18ddc9a98eec	268323db-7e11-42d4-85ee-7d4337798131	dc42f275-da07-437e-9c47-32100563d610	f5196497-9f26-4f98-a240-1bb0c8c60639	2026-02-02T00:00:00.0000000	08:30:00	09:00:00	0	1	Consulta de primeira vez - POC TeleCuidar	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-02-05T10:29:26.7482141Z	2026-02-05T10:29:26.7482142Z	\N	\N	\N	\N	\N	\N	0	\N	\N	0	0	\N	\N	\N
5879366d-5f41-4970-bdf8-57566457c2b6	454458dd-c79a-4fe1-8d7c-2e5d712ee871	f7fa3199-a452-4244-aabd-4fff524edbd8	a3e0437e-76c6-478a-a465-1d1b81e8bbb9	2026-02-03T00:00:00.0000000	11:30:00	12:00:00	2	0	Consulta de retorno - POC TeleCuidar	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-02-05T10:29:26.7546022Z	2026-02-05T10:29:26.7546023Z	\N	\N	\N	\N	\N	\N	0	\N	\N	0	0	\N	\N	\N
588bacda-9273-40d6-9597-4e54f6859d32	1b136568-233e-4201-9c43-f0445a6017b3	321c02a6-3abb-4158-93e9-41ce25573586	ae03858a-9cb0-4361-8857-857435949d82	2026-02-03T00:00:00.0000000	10:30:00	11:00:00	2	1	Consulta de retorno - POC TeleCuidar	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-02-05T10:29:26.7534187Z	2026-02-05T10:29:26.7534188Z	\N	\N	\N	\N	\N	\N	0	\N	\N	0	0	\N	\N	\N
6717dfb5-dc7a-48e7-b722-765490619077	454458dd-c79a-4fe1-8d7c-2e5d712ee871	321c02a6-3abb-4158-93e9-41ce25573586	ae03858a-9cb0-4361-8857-857435949d82	2026-02-03T00:00:00.0000000	09:00:00	09:30:00	4	0	Consulta de retorno - POC TeleCuidar	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-02-05T10:29:26.7528424Z	2026-02-05T10:29:26.7528425Z	\N	\N	\N	\N	\N	\N	0	\N	\N	0	0	\N	\N	\N
75e97f9a-e600-4a9c-b3a0-e61b6da48d31	268323db-7e11-42d4-85ee-7d4337798131	09c33afc-d053-4f1d-946d-aba173642b36	8ee8d058-d70b-4bd0-916f-5dbe9621caf5	2026-02-02T00:00:00.0000000	17:30:00	18:00:00	1	0	Consulta de retorno - POC TeleCuidar	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-02-05T10:29:26.7497581Z	2026-02-05T10:29:26.7497583Z	\N	\N	\N	\N	\N	\N	0	\N	\N	0	0	\N	\N	\N
786b91e5-122e-4c48-8397-812cd029ebcf	454458dd-c79a-4fe1-8d7c-2e5d712ee871	dc42f275-da07-437e-9c47-32100563d610	f5196497-9f26-4f98-a240-1bb0c8c60639	2026-02-04T00:00:00.0000000	09:00:00	09:30:00	2	1	Consulta de retorno - POC TeleCuidar	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-02-05T10:29:26.7485304Z	2026-02-05T10:29:26.7485307Z	\N	\N	\N	\N	\N	\N	0	\N	\N	0	0	\N	\N	\N
7b0ca158-8557-4b4b-a2f4-18805dc96a27	62f70bc8-e96e-4308-bffc-15bcada66ed7	09c33afc-d053-4f1d-946d-aba173642b36	8ee8d058-d70b-4bd0-916f-5dbe9621caf5	2026-02-11T00:00:00.0000000	13:30:00	14:00:00	0	1	Consulta de primeira vez - POC TeleCuidar	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-02-05T10:29:26.7516286Z	2026-02-05T10:29:26.7516287Z	\N	\N	\N	\N	\N	\N	0	\N	\N	0	0	\N	\N	\N
7f4b82d4-fbe5-4f3b-ba8a-4c89b1bdd16b	454458dd-c79a-4fe1-8d7c-2e5d712ee871	dc42f275-da07-437e-9c47-32100563d610	f5196497-9f26-4f98-a240-1bb0c8c60639	2026-02-03T00:00:00.0000000	10:30:00	11:00:00	2	0	Consulta de retorno - POC TeleCuidar	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-02-05T10:29:26.7483764Z	2026-02-05T10:29:26.7483765Z	\N	\N	\N	\N	\N	\N	0	\N	\N	0	0	\N	\N	\N
7fa24477-be49-4d16-949f-696a1e8fa152	268323db-7e11-42d4-85ee-7d4337798131	321c02a6-3abb-4158-93e9-41ce25573586	ae03858a-9cb0-4361-8857-857435949d82	2026-02-02T00:00:00.0000000	11:30:00	12:00:00	0	0	Consulta de primeira vez - POC TeleCuidar	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-02-05T10:29:26.7520995Z	2026-02-05T10:29:26.7520998Z	\N	\N	\N	\N	\N	\N	0	\N	\N	0	0	\N	\N	\N
80f1b2bf-8825-4da4-8457-971e2a187244	454458dd-c79a-4fe1-8d7c-2e5d712ee871	c8d3e9ae-1b97-4758-8789-5ef40dd70abb	5b4fc232-61f3-4066-912d-d9367d818798	2026-02-02T00:00:00.0000000	09:30:00	10:00:00	1	0	Consulta de retorno - POC TeleCuidar	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-02-05T10:29:26.7468446Z	2026-02-05T10:29:26.7468453Z	\N	\N	\N	\N	\N	\N	0	\N	\N	0	0	\N	\N	\N
84503d8c-49b9-4f0f-9d8a-698bb362b1c3	454458dd-c79a-4fe1-8d7c-2e5d712ee871	321c02a6-3abb-4158-93e9-41ce25573586	ae03858a-9cb0-4361-8857-857435949d82	2026-02-03T00:00:00.0000000	12:00:00	12:30:00	0	6	Consulta de primeira vez - POC TeleCuidar	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-02-05T10:29:26.7526940Z	2026-02-05T10:29:26.7526941Z	\N	\N	\N	\N	\N	\N	0	\N	\N	0	0	\N	\N	\N
84871467-6779-4955-b8a6-3199fdf1bf6d	1b136568-233e-4201-9c43-f0445a6017b3	f7fa3199-a452-4244-aabd-4fff524edbd8	a3e0437e-76c6-478a-a465-1d1b81e8bbb9	2026-02-09T00:00:00.0000000	11:30:00	12:00:00	4	1	Consulta de retorno - POC TeleCuidar	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-02-05T10:29:26.7551721Z	2026-02-05T10:29:26.7551723Z	\N	\N	\N	\N	\N	\N	0	\N	\N	0	0	\N	\N	\N
88856f77-47a3-4416-afa4-c72376b840df	1b136568-233e-4201-9c43-f0445a6017b3	09c33afc-d053-4f1d-946d-aba173642b36	8ee8d058-d70b-4bd0-916f-5dbe9621caf5	2026-02-09T00:00:00.0000000	10:30:00	11:00:00	4	1	Consulta de retorno - POC TeleCuidar	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-02-05T10:29:26.7513606Z	2026-02-05T10:29:26.7513607Z	\N	\N	\N	\N	\N	\N	0	\N	\N	0	0	\N	\N	\N
8c2b5810-b742-430f-a3dd-1f3f1e97fc4f	1a25bc58-0f72-4f59-a892-0d6ee51f0c07	09c33afc-d053-4f1d-946d-aba173642b36	8ee8d058-d70b-4bd0-916f-5dbe9621caf5	2026-02-05T00:00:00.0000000	08:30:00	09:00:00	1	6	Consulta de retorno - POC TeleCuidar	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-02-05T10:29:26.7509399Z	2026-02-05T10:29:26.7509402Z	\N	\N	\N	\N	\N	\N	0	\N	\N	0	0	\N	\N	\N
92d70edb-6a0d-46c4-a5d8-b5ce73049142	1a25bc58-0f72-4f59-a892-0d6ee51f0c07	f7fa3199-a452-4244-aabd-4fff524edbd8	a3e0437e-76c6-478a-a465-1d1b81e8bbb9	2026-02-05T00:00:00.0000000	08:00:00	08:30:00	2	6	Consulta de retorno - POC TeleCuidar	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-02-05T10:29:26.7548494Z	2026-02-05T10:29:26.7548495Z	\N	\N	\N	\N	\N	\N	0	\N	\N	0	0	\N	\N	\N
9b17bde5-c780-4d30-931e-8955516c1aa3	1a25bc58-0f72-4f59-a892-0d6ee51f0c07	09c33afc-d053-4f1d-946d-aba173642b36	8ee8d058-d70b-4bd0-916f-5dbe9621caf5	2026-02-06T00:00:00.0000000	15:00:00	15:30:00	1	0	Consulta de retorno - POC TeleCuidar	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-02-05T10:29:26.7510626Z	2026-02-05T10:29:26.7510627Z	\N	\N	\N	\N	\N	\N	0	\N	\N	0	0	\N	\N	\N
b7b71d87-57b0-443b-92cb-95bf4db2218f	268323db-7e11-42d4-85ee-7d4337798131	c8d3e9ae-1b97-4758-8789-5ef40dd70abb	5b4fc232-61f3-4066-912d-d9367d818798	2026-02-02T00:00:00.0000000	09:00:00	09:30:00	2	1	Consulta de retorno - POC TeleCuidar	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-02-05T10:29:26.7465866Z	2026-02-05T10:29:26.7465871Z	\N	\N	\N	\N	\N	\N	0	\N	\N	0	0	\N	\N	\N
bd1f58a2-0bbd-41db-b202-236a2e13addc	1b136568-233e-4201-9c43-f0445a6017b3	09c33afc-d053-4f1d-946d-aba173642b36	8ee8d058-d70b-4bd0-916f-5dbe9621caf5	2026-02-06T00:00:00.0000000	11:30:00	12:00:00	0	0	Consulta de primeira vez - POC TeleCuidar	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-02-05T10:29:26.7511897Z	2026-02-05T10:29:26.7511897Z	\N	\N	\N	\N	\N	\N	0	\N	\N	0	0	\N	\N	\N
bdd0e2ae-31c1-41dd-91a9-6c49947702ae	62f70bc8-e96e-4308-bffc-15bcada66ed7	321c02a6-3abb-4158-93e9-41ce25573586	ae03858a-9cb0-4361-8857-857435949d82	2026-02-04T00:00:00.0000000	10:30:00	11:00:00	4	6	Consulta de retorno - POC TeleCuidar	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-02-05T10:29:26.7538302Z	2026-02-05T10:29:26.7538303Z	\N	\N	\N	\N	\N	\N	0	\N	\N	0	0	\N	\N	\N
c7b22f03-f587-4261-897b-adbf7a855026	1b136568-233e-4201-9c43-f0445a6017b3	f7fa3199-a452-4244-aabd-4fff524edbd8	a3e0437e-76c6-478a-a465-1d1b81e8bbb9	2026-02-06T00:00:00.0000000	17:30:00	18:00:00	0	1	Consulta de primeira vez - POC TeleCuidar	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-02-05T10:29:26.7550414Z	2026-02-05T10:29:26.7550415Z	\N	\N	\N	\N	\N	\N	0	\N	\N	0	0	\N	\N	\N
cbbe2078-2bd1-473a-b110-2bc33550461d	454458dd-c79a-4fe1-8d7c-2e5d712ee871	c8d3e9ae-1b97-4758-8789-5ef40dd70abb	5b4fc232-61f3-4066-912d-d9367d818798	2026-02-03T00:00:00.0000000	13:00:00	13:30:00	1	0	Consulta de retorno - POC TeleCuidar	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-02-05T10:29:26.7469899Z	2026-02-05T10:29:26.7469900Z	\N	\N	\N	\N	\N	\N	0	\N	\N	0	0	\N	\N	\N
ceaa4490-b958-46c8-a549-304ad8e4f597	62f70bc8-e96e-4308-bffc-15bcada66ed7	09c33afc-d053-4f1d-946d-aba173642b36	8ee8d058-d70b-4bd0-916f-5dbe9621caf5	2026-02-10T00:00:00.0000000	15:30:00	16:00:00	1	1	Consulta de retorno - POC TeleCuidar	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-02-05T10:29:26.7514871Z	2026-02-05T10:29:26.7514871Z	\N	\N	\N	\N	\N	\N	0	\N	\N	0	0	\N	\N	\N
d2e2f9dd-dbb2-436f-aed6-3ef5b3b1270b	62f70bc8-e96e-4308-bffc-15bcada66ed7	f7fa3199-a452-4244-aabd-4fff524edbd8	a3e0437e-76c6-478a-a465-1d1b81e8bbb9	2026-02-11T00:00:00.0000000	13:30:00	14:00:00	4	0	Consulta de retorno - POC TeleCuidar	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-02-05T10:29:26.7554121Z	2026-02-05T10:29:26.7554121Z	\N	\N	\N	\N	\N	\N	0	\N	\N	0	0	\N	\N	\N
d7d3f0d7-9852-4955-bb9e-67982a095b43	454458dd-c79a-4fe1-8d7c-2e5d712ee871	09c33afc-d053-4f1d-946d-aba173642b36	8ee8d058-d70b-4bd0-916f-5dbe9621caf5	2026-02-04T00:00:00.0000000	10:30:00	11:00:00	2	1	Consulta de retorno - POC TeleCuidar	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-02-05T10:29:26.7507725Z	2026-02-05T10:29:26.7507728Z	\N	\N	\N	\N	\N	\N	0	\N	\N	0	0	\N	\N	\N
d823d232-eb85-41ad-9f62-29fbb0416f04	268323db-7e11-42d4-85ee-7d4337798131	dc42f275-da07-437e-9c47-32100563d610	f5196497-9f26-4f98-a240-1bb0c8c60639	2026-02-02T00:00:00.0000000	15:00:00	15:30:00	0	0	Consulta de primeira vez - POC TeleCuidar	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-02-05T10:29:26.7479697Z	2026-02-05T10:29:26.7479699Z	\N	\N	\N	\N	\N	\N	0	\N	\N	0	0	\N	\N	\N
da1f11a7-6eef-47d6-9d73-3be2c15cff6f	268323db-7e11-42d4-85ee-7d4337798131	321c02a6-3abb-4158-93e9-41ce25573586	ae03858a-9cb0-4361-8857-857435949d82	2026-02-03T00:00:00.0000000	10:00:00	10:30:00	2	0	Consulta de retorno - POC TeleCuidar	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-02-05T10:29:26.7524662Z	2026-02-05T10:29:26.7524665Z	\N	\N	\N	\N	\N	\N	0	\N	\N	0	0	\N	\N	\N
e7a5571b-2558-4fd6-bc30-5ce01928981e	1a25bc58-0f72-4f59-a892-0d6ee51f0c07	dc42f275-da07-437e-9c47-32100563d610	f5196497-9f26-4f98-a240-1bb0c8c60639	2026-02-04T00:00:00.0000000	10:00:00	10:30:00	1	0	Consulta de retorno - POC TeleCuidar	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-02-05T10:29:26.7488216Z	2026-02-05T10:29:26.7488223Z	\N	\N	\N	\N	\N	\N	0	\N	\N	0	0	\N	\N	\N
e9dcda72-75b4-4eaa-b6d4-354051441d09	62f70bc8-e96e-4308-bffc-15bcada66ed7	dc42f275-da07-437e-9c47-32100563d610	f5196497-9f26-4f98-a240-1bb0c8c60639	2026-02-06T00:00:00.0000000	12:00:00	12:30:00	0	1	Consulta de primeira vez - POC TeleCuidar	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-02-05T10:29:26.7492661Z	2026-02-05T10:29:26.7492662Z	\N	\N	\N	\N	\N	\N	0	\N	\N	0	0	\N	\N	\N
e63e639a-e700-4ad3-803e-1ac0394290d4	1b136568-233e-4201-9c43-f0445a6017b3	dc42f275-da07-437e-9c47-32100563d610	f5196497-9f26-4f98-a240-1bb0c8c60639	2026-02-05T00:00:00.0000000	08:30:00	09:00:00	2	3	Consulta de retorno - POC TeleCuidar	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-02-05T10:29:26.7491158Z	2026-02-05T17:03:32.9925213Z	\N	\N	\N	\N	\N	\N	0	\N	2026-02-05T17:03:32.9923795Z	0	0	\N	\N	\N
d9e50997-f8f1-45f2-9190-7f54269ce741	62f70bc8-e96e-4308-bffc-15bcada66ed7	321c02a6-3abb-4158-93e9-41ce25573586	ae03858a-9cb0-4361-8857-857435949d82	2026-02-05T00:00:00.0000000	09:30:00	10:00:00	1	3	Consulta de retorno - POC TeleCuidar	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-02-05T10:29:26.7539916Z	2026-02-05T16:02:02.1166443Z	\N	\N	\N	\N	\N	\N	0	\N	2026-02-05T16:02:02.1165238Z	0	0	\N	\N	\N
f0050714-2e0d-4c42-9530-e98d8d157592	1b136568-233e-4201-9c43-f0445a6017b3	dc42f275-da07-437e-9c47-32100563d610	f5196497-9f26-4f98-a240-1bb0c8c60639	2026-02-04T00:00:00.0000000	08:30:00	09:00:00	1	0	Consulta de retorno - POC TeleCuidar	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-02-05T10:29:26.7489727Z	2026-02-05T10:29:26.7489729Z	\N	\N	\N	\N	\N	\N	0	\N	\N	0	0	\N	\N	\N
f90ee8bf-557d-45d9-aab9-9e631ff67a09	454458dd-c79a-4fe1-8d7c-2e5d712ee871	f7fa3199-a452-4244-aabd-4fff524edbd8	a3e0437e-76c6-478a-a465-1d1b81e8bbb9	2026-02-04T00:00:00.0000000	17:30:00	18:00:00	0	0	Consulta de primeira vez - POC TeleCuidar	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-02-05T10:29:26.7547346Z	2026-02-05T10:29:26.7547347Z	\N	\N	\N	\N	\N	\N	0	\N	\N	0	0	\N	\N	\N
fa72357a-ac61-4e5f-afea-a170acef2ccc	1a25bc58-0f72-4f59-a892-0d6ee51f0c07	c8d3e9ae-1b97-4758-8789-5ef40dd70abb	5b4fc232-61f3-4066-912d-d9367d818798	2026-02-03T00:00:00.0000000	13:00:00	13:30:00	2	1	Consulta de retorno - POC TeleCuidar	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-02-05T10:29:26.7471403Z	2026-02-05T10:29:26.7471403Z	\N	\N	\N	\N	\N	\N	0	\N	\N	0	0	\N	\N	\N
97a70547-5fa9-420d-a634-f13730db5edd	62f70bc8-e96e-4308-bffc-15bcada66ed7	dc42f275-da07-437e-9c47-32100563d610	f5196497-9f26-4f98-a240-1bb0c8c60639	2026-02-06T00:00:00.0000000	08:00:00	08:30:00	0	3	Consulta de primeira vez - POC TeleCuidar	\N	\N	{"HeartRate":140,"BloodPressureSystolic":null,"BloodPressureDiastolic":null,"OxygenSaturation":null,"Temperature":null,"RespiratoryRate":null,"Glucose":null,"Weight":null,"Height":null,"LastUpdated":"2026-02-06T07:43:54.4084298Z"}	\N	\N	\N	\N	\N	\N	\N	\N	2026-02-05T10:29:26.7494083Z	2026-02-06T07:53:54.2377628Z	\N	\N	\N	\N	\N	\N	0	\N	2026-02-06T07:53:54.2376928Z	0	0	\N	\N	\N
f4dd7cde-261b-4f54-aa92-7d58a499d0b4	1a25bc58-0f72-4f59-a892-0d6ee51f0c07	f7fa3199-a452-4244-aabd-4fff524edbd8	a3e0437e-76c6-478a-a465-1d1b81e8bbb9	2026-02-05T00:00:00.0000000	12:30:00	13:00:00	0	3	Consulta de primeira vez - POC TeleCuidar	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-02-05T10:29:26.7549485Z	2026-02-05T13:52:33.0065823Z	\N	\N	\N	\N	\N	\N	0	\N	2026-02-05T13:52:33.0063431Z	0	0	\N	\N	\N
e7459b24-c109-4fa0-a374-576312f67527	62f70bc8-e96e-4308-bffc-15bcada66ed7	c8d3e9ae-1b97-4758-8789-5ef40dd70abb	5b4fc232-61f3-4066-912d-d9367d818798	2026-02-05T00:00:00.0000000	09:00:00	09:30:00	2	3	Consulta de retorno - POC TeleCuidar	\N	\N	{"HeartRate":null,"BloodPressureSystolic":116,"BloodPressureDiastolic":77,"OxygenSaturation":null,"Temperature":null,"RespiratoryRate":null,"Glucose":null,"Weight":14.85,"Height":null,"LastUpdated":"2026-02-05T23:47:25.3348304Z"}	\N	\N	\N	\N	\N	\N	\N	\N	2026-02-05T10:29:26.7476239Z	2026-02-06T00:34:43.1180854Z	\N	\N	\N	\N	\N	\N	0	\N	2026-02-06T00:34:43.1179612Z	0	0	\N	\N	\N
aa4c6779-94be-4a1b-a674-636d6e44f978	62f70bc8-e96e-4308-bffc-15bcada66ed7	c8d3e9ae-1b97-4758-8789-5ef40dd70abb	5b4fc232-61f3-4066-912d-d9367d818798	2026-02-05T00:00:00.0000000	16:00:00	16:30:00	4	3	Consulta de retorno - POC TeleCuidar	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-02-05T10:29:26.7477232Z	2026-02-06T02:36:32.9903827Z	\N	\N	\N	\N	\N	\N	0	\N	2026-02-06T02:36:32.9902932Z	0	0	\N	\N	\N
\.


--
-- Data for Name: Attachments; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."Attachments" ("Id", "AppointmentId", "Title", "FileName", "FilePath", "FileType", "FileSize", "CreatedAt", "UpdatedAt") FROM stdin;
\.


--
-- Data for Name: AuditLogs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."AuditLogs" ("Id", "UserId", "Action", "EntityType", "EntityId", "OldValues", "NewValues", "IpAddress", "UserAgent", "CreatedAt", "UpdatedAt", "AccessReason", "DataCategory", "PatientCpf", "PatientId") FROM stdin;
01633596-1bd1-4bbc-b9ee-bf712c87f50d	dc42f275-da07-437e-9c47-32100563d610	login	User	dc42f275-da07-437e-9c47-32100563d610	\N	{"Email":"med_gt@telecuidar.com","LoginTime":"2026-02-05T10:37:11.3777466Z"}	127.0.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; pt-BR) WindowsPowerShell/5.1.26100.7462	2026-02-05T10:37:11.3962339Z	2026-02-05T10:37:11.3962340Z	\N	\N	\N	\N
e5598318-54b2-4f49-b5ca-c476ba4c7204	c8d3e9ae-1b97-4758-8789-5ef40dd70abb	login	User	c8d3e9ae-1b97-4758-8789-5ef40dd70abb	\N	{"Email":"med_aj@telecuidar.com","LoginTime":"2026-02-05T10:37:45.4397116Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-05T10:37:45.4409039Z	2026-02-05T10:37:45.4409041Z	\N	\N	\N	\N
53104ddc-5610-4fff-b2ee-2fef997c3255	c8d3e9ae-1b97-4758-8789-5ef40dd70abb	jitsi_access	Appointment	aa4c6779-94be-4a1b-a674-636d6e44f978	\N	{"RoomName":"aa4c677994be4a1ba674636d6e44f978","IsModerator":true,"Domain":"localhost:8443"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-05T10:37:55.1844480Z	2026-02-05T10:37:55.1844481Z	\N	\N	\N	\N
992a9782-e9a3-465e-9e34-fd94557a45c4	dc42f275-da07-437e-9c47-32100563d610	login	User	dc42f275-da07-437e-9c47-32100563d610	\N	{"Email":"med_gt@telecuidar.com","LoginTime":"2026-02-05T10:57:32.8846416Z"}	127.0.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; pt-BR) WindowsPowerShell/5.1.26100.7462	2026-02-05T10:57:32.8847352Z	2026-02-05T10:57:32.8847353Z	\N	\N	\N	\N
2e19092b-f014-46b9-9857-35a293eec33f	0f8e0f55-b270-46d7-bf58-8831e5705cf8	login	User	0f8e0f55-b270-46d7-bf58-8831e5705cf8	\N	{"Email":"enf_do@telecuidar.com","LoginTime":"2026-02-05T10:59:11.2281355Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-05T10:59:11.2281992Z	2026-02-05T10:59:11.2281992Z	\N	\N	\N	\N
7fc0d6d1-85b5-493f-814b-3cbcf0ee7d32	0f8e0f55-b270-46d7-bf58-8831e5705cf8	jitsi_access	Appointment	e7459b24-c109-4fa0-a374-576312f67527	\N	{"RoomName":"e7459b24c1094fa0a374576312f67527","IsModerator":false,"Domain":"localhost:8443"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-05T11:03:20.6784890Z	2026-02-05T11:03:20.6784891Z	\N	\N	\N	\N
58f7d8d9-8d86-4190-8815-e8dcd61b2eae	0f8e0f55-b270-46d7-bf58-8831e5705cf8	jitsi_access	Appointment	e7459b24-c109-4fa0-a374-576312f67527	\N	{"RoomName":"e7459b24c1094fa0a374576312f67527","IsModerator":false,"Domain":"localhost:8443"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-05T11:15:37.0515259Z	2026-02-05T11:15:37.0515261Z	\N	\N	\N	\N
8d3827d0-c79b-4286-9cc1-56b6f2915a31	0f8e0f55-b270-46d7-bf58-8831e5705cf8	login	User	0f8e0f55-b270-46d7-bf58-8831e5705cf8	\N	{"Email":"enf_do@telecuidar.com","LoginTime":"2026-02-05T11:35:44.3229037Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-05T11:35:44.3245982Z	2026-02-05T11:35:44.3245983Z	\N	\N	\N	\N
09d47273-8a03-4128-9d0c-a6901de88fa0	0f8e0f55-b270-46d7-bf58-8831e5705cf8	jitsi_access	Appointment	e63e639a-e700-4ad3-803e-1ac0394290d4	\N	{"RoomName":"e63e639ae7004ad3803e1ac0394290d4","IsModerator":false,"Domain":"localhost:8443"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-05T11:35:51.4036876Z	2026-02-05T11:35:51.4036876Z	\N	\N	\N	\N
e5d8cb64-6ce7-4d5d-bd91-8c65aefb790b	0f8e0f55-b270-46d7-bf58-8831e5705cf8	login	User	0f8e0f55-b270-46d7-bf58-8831e5705cf8	\N	{"Email":"enf_do@telecuidar.com","LoginTime":"2026-02-05T12:51:46.0975935Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-05T12:51:46.1173597Z	2026-02-05T12:51:46.1173601Z	\N	\N	\N	\N
1ade6921-7e8b-4e37-880a-a844a1738d10	0f8e0f55-b270-46d7-bf58-8831e5705cf8	jitsi_access	Appointment	97a70547-5fa9-420d-a634-f13730db5edd	\N	{"RoomName":"97a705475fa9420da634f13730db5edd","IsModerator":false,"Domain":"localhost:8443"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-05T12:53:27.5132766Z	2026-02-05T12:53:27.5132769Z	\N	\N	\N	\N
e5538699-21d4-4c3e-812b-2f18b3fd345a	0f8e0f55-b270-46d7-bf58-8831e5705cf8	jitsi_access	Appointment	97a70547-5fa9-420d-a634-f13730db5edd	\N	{"RoomName":"97a705475fa9420da634f13730db5edd","IsModerator":false,"Domain":"localhost:8443"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-05T13:20:14.9781573Z	2026-02-05T13:20:14.9781577Z	\N	\N	\N	\N
d31c98a1-ac14-43f4-8299-3122211760e2	0f8e0f55-b270-46d7-bf58-8831e5705cf8	jitsi_access	Appointment	97a70547-5fa9-420d-a634-f13730db5edd	\N	{"RoomName":"97a705475fa9420da634f13730db5edd","IsModerator":false,"Domain":"localhost:8443"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-05T13:20:15.4474492Z	2026-02-05T13:20:15.4474493Z	\N	\N	\N	\N
1ed0501c-684e-44ca-a394-fe0145f1dc0e	0f8e0f55-b270-46d7-bf58-8831e5705cf8	jitsi_access	Appointment	d9e50997-f8f1-45f2-9190-7f54269ce741	\N	{"RoomName":"d9e50997f8f145f291907f54269ce741","IsModerator":false,"Domain":"localhost:8443"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-05T13:21:31.2958412Z	2026-02-05T13:21:31.2958413Z	\N	\N	\N	\N
2186e1fe-2410-49d7-80f6-df69afdc58bf	0f8e0f55-b270-46d7-bf58-8831e5705cf8	jitsi_access	Appointment	f4dd7cde-261b-4f54-aa92-7d58a499d0b4	\N	{"RoomName":"f4dd7cde261b4f54aa927d58a499d0b4","IsModerator":false,"Domain":"localhost:8443"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-05T13:21:51.6400773Z	2026-02-05T13:21:51.6400774Z	\N	\N	\N	\N
ed7ae556-0633-4140-8b57-00590a5cf45c	0f8e0f55-b270-46d7-bf58-8831e5705cf8	jitsi_access	Appointment	f4dd7cde-261b-4f54-aa92-7d58a499d0b4	\N	{"RoomName":"f4dd7cde261b4f54aa927d58a499d0b4","IsModerator":false,"Domain":"localhost:8443"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-05T13:25:58.2142985Z	2026-02-05T13:25:58.2142986Z	\N	\N	\N	\N
080dd568-8db3-4dcb-b388-0ddd3cd07c81	0f8e0f55-b270-46d7-bf58-8831e5705cf8	login	User	0f8e0f55-b270-46d7-bf58-8831e5705cf8	\N	{"Email":"enf_do@telecuidar.com","LoginTime":"2026-02-05T14:01:56.711656Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-05T14:01:56.7357778Z	2026-02-05T14:01:56.7357780Z	\N	\N	\N	\N
f6e64a93-19af-415e-a899-1aba654d6c26	c8d3e9ae-1b97-4758-8789-5ef40dd70abb	login	User	c8d3e9ae-1b97-4758-8789-5ef40dd70abb	\N	{"Email":"med_aj@telecuidar.com","LoginTime":"2026-02-05T14:02:32.9480668Z"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-05T14:02:32.9484562Z	2026-02-05T14:02:32.9484563Z	\N	\N	\N	\N
37b49d75-2e5c-4cb5-977e-1f124cff16a6	0f8e0f55-b270-46d7-bf58-8831e5705cf8	jitsi_access	Appointment	aa4c6779-94be-4a1b-a674-636d6e44f978	\N	{"RoomName":"aa4c677994be4a1ba674636d6e44f978","IsModerator":false,"Domain":"localhost:8443"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-05T14:03:17.7783683Z	2026-02-05T14:03:17.7783685Z	\N	\N	\N	\N
3fe3ba9c-cb04-4291-ba2b-cf04adeef180	0f8e0f55-b270-46d7-bf58-8831e5705cf8	jitsi_access	Appointment	aa4c6779-94be-4a1b-a674-636d6e44f978	\N	{"RoomName":"aa4c677994be4a1ba674636d6e44f978","IsModerator":false,"Domain":"localhost:8443"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-05T14:17:54.8446527Z	2026-02-05T14:17:54.8446530Z	\N	\N	\N	\N
efc46066-a3c3-499c-979b-f3bfc7511e46	0f8e0f55-b270-46d7-bf58-8831e5705cf8	jitsi_access	Appointment	aa4c6779-94be-4a1b-a674-636d6e44f978	\N	{"RoomName":"aa4c677994be4a1ba674636d6e44f978","IsModerator":false,"Domain":"localhost:8443"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-05T14:17:55.0534837Z	2026-02-05T14:17:55.0534838Z	\N	\N	\N	\N
fe602ec6-11a6-4621-9976-bba42aa72096	0f8e0f55-b270-46d7-bf58-8831e5705cf8	login	User	0f8e0f55-b270-46d7-bf58-8831e5705cf8	\N	{"Email":"enf_do@telecuidar.com","LoginTime":"2026-02-05T14:19:01.6813025Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-05T14:19:01.6814008Z	2026-02-05T14:19:01.6814009Z	\N	\N	\N	\N
033d521d-3014-4e1a-98aa-842a1a4c7646	0f8e0f55-b270-46d7-bf58-8831e5705cf8	jitsi_access	Appointment	e7459b24-c109-4fa0-a374-576312f67527	\N	{"RoomName":"e7459b24c1094fa0a374576312f67527","IsModerator":false,"Domain":"localhost:8443"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-05T14:21:16.1023906Z	2026-02-05T14:21:16.1023906Z	\N	\N	\N	\N
f704ca19-274e-4c20-a7cc-9e9bf8f7f323	c8d3e9ae-1b97-4758-8789-5ef40dd70abb	jitsi_access	Appointment	e7459b24-c109-4fa0-a374-576312f67527	\N	{"RoomName":"e7459b24c1094fa0a374576312f67527","IsModerator":true,"Domain":"192.168.18.31:8443"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-05T14:21:28.8913234Z	2026-02-05T14:21:28.8913236Z	\N	\N	\N	\N
ca1b0698-be1b-4807-9ce9-17cc9ec60a87	0f8e0f55-b270-46d7-bf58-8831e5705cf8	jitsi_access	Appointment	aa4c6779-94be-4a1b-a674-636d6e44f978	\N	{"RoomName":"aa4c677994be4a1ba674636d6e44f978","IsModerator":false,"Domain":"localhost:8443"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-05T14:23:04.9705971Z	2026-02-05T14:23:04.9705974Z	\N	\N	\N	\N
d6165c22-544b-4e3a-9f18-4b35180357fc	c8d3e9ae-1b97-4758-8789-5ef40dd70abb	login	User	c8d3e9ae-1b97-4758-8789-5ef40dd70abb	\N	{"Email":"med_aj@telecuidar.com","LoginTime":"2026-02-05T14:24:38.5864537Z"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-05T14:24:38.5865283Z	2026-02-05T14:24:38.5865283Z	\N	\N	\N	\N
42a6f70c-297f-439b-866c-f9b1b9926540	0f8e0f55-b270-46d7-bf58-8831e5705cf8	jitsi_access	Appointment	aa4c6779-94be-4a1b-a674-636d6e44f978	\N	{"RoomName":"aa4c677994be4a1ba674636d6e44f978","IsModerator":false,"Domain":"localhost:8443"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-05T14:25:02.8718898Z	2026-02-05T14:25:02.8718898Z	\N	\N	\N	\N
c81aff58-7138-4607-a6d7-e3627621bbfc	0f8e0f55-b270-46d7-bf58-8831e5705cf8	jitsi_access	Appointment	aa4c6779-94be-4a1b-a674-636d6e44f978	\N	{"RoomName":"aa4c677994be4a1ba674636d6e44f978","IsModerator":false,"Domain":"localhost:8443"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-05T14:29:49.9823411Z	2026-02-05T14:29:49.9823414Z	\N	\N	\N	\N
731ba7f6-aa49-43bf-a5ba-286aecd2fbe8	0f8e0f55-b270-46d7-bf58-8831e5705cf8	jitsi_access	Appointment	aa4c6779-94be-4a1b-a674-636d6e44f978	\N	{"RoomName":"aa4c677994be4a1ba674636d6e44f978","IsModerator":false,"Domain":"localhost:8443"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-05T14:29:50.2453631Z	2026-02-05T14:29:50.2453631Z	\N	\N	\N	\N
a8149f2f-2529-4f48-b1aa-81fbdb313c84	dc42f275-da07-437e-9c47-32100563d610	login	User	dc42f275-da07-437e-9c47-32100563d610	\N	{"Email":"med_gt@telecuidar.com","LoginTime":"2026-02-05T14:32:43.4932116Z"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-05T14:32:43.4942662Z	2026-02-05T14:32:43.4942662Z	\N	\N	\N	\N
765ea628-ead8-4fd0-8216-51f21c400fb1	0f8e0f55-b270-46d7-bf58-8831e5705cf8	jitsi_access	Appointment	e63e639a-e700-4ad3-803e-1ac0394290d4	\N	{"RoomName":"e63e639ae7004ad3803e1ac0394290d4","IsModerator":false,"Domain":"localhost:8443"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-05T14:33:14.5357691Z	2026-02-05T14:33:14.5357692Z	\N	\N	\N	\N
545f4d35-0636-44b3-91e1-8a0ae6ca3bc0	dc42f275-da07-437e-9c47-32100563d610	jitsi_access	Appointment	e63e639a-e700-4ad3-803e-1ac0394290d4	\N	{"RoomName":"e63e639ae7004ad3803e1ac0394290d4","IsModerator":true,"Domain":"192.168.18.31:8443"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-05T14:33:30.9466634Z	2026-02-05T14:33:30.9466636Z	\N	\N	\N	\N
ee53dccd-897f-48f2-a339-33ba5feaa928	0f8e0f55-b270-46d7-bf58-8831e5705cf8	jitsi_access	Appointment	e63e639a-e700-4ad3-803e-1ac0394290d4	\N	{"RoomName":"e63e639ae7004ad3803e1ac0394290d4","IsModerator":false,"Domain":"localhost:8443"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-05T14:33:42.1286660Z	2026-02-05T14:33:42.1286661Z	\N	\N	\N	\N
b19d202b-2bd6-4e5e-921a-07cfc0685235	dc42f275-da07-437e-9c47-32100563d610	login	User	dc42f275-da07-437e-9c47-32100563d610	\N	{"Email":"med_gt@telecuidar.com","LoginTime":"2026-02-05T14:39:31.047712Z"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-05T14:39:31.0478012Z	2026-02-05T14:39:31.0478012Z	\N	\N	\N	\N
8540826d-ebd1-416c-a24e-1d09bef027b2	0f8e0f55-b270-46d7-bf58-8831e5705cf8	login	User	0f8e0f55-b270-46d7-bf58-8831e5705cf8	\N	{"Email":"enf_do@telecuidar.com","LoginTime":"2026-02-05T14:39:45.7392827Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-05T14:39:45.7393551Z	2026-02-05T14:39:45.7393552Z	\N	\N	\N	\N
4b910b78-94ab-4564-9695-1ddc6fc27727	0f8e0f55-b270-46d7-bf58-8831e5705cf8	jitsi_access	Appointment	e63e639a-e700-4ad3-803e-1ac0394290d4	\N	{"RoomName":"e63e639ae7004ad3803e1ac0394290d4","IsModerator":false,"Domain":"localhost:8443"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-05T14:39:56.4636866Z	2026-02-05T14:39:56.4636869Z	\N	\N	\N	\N
0194c7aa-56b7-46d4-a2d7-f6dea80d609b	dc42f275-da07-437e-9c47-32100563d610	jitsi_access	Appointment	e63e639a-e700-4ad3-803e-1ac0394290d4	\N	{"RoomName":"e63e639ae7004ad3803e1ac0394290d4","IsModerator":true,"Domain":"192.168.18.31:8443"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-05T14:40:14.1564512Z	2026-02-05T14:40:14.1564512Z	\N	\N	\N	\N
ff3aaad9-4563-4d9e-ae5b-c99eb726a2e5	0f8e0f55-b270-46d7-bf58-8831e5705cf8	login	User	0f8e0f55-b270-46d7-bf58-8831e5705cf8	\N	{"Email":"enf_do@telecuidar.com","LoginTime":"2026-02-05T15:36:57.8064668Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-05T15:36:57.8361127Z	2026-02-05T15:36:57.8361131Z	\N	\N	\N	\N
19ae6caa-36ae-425d-8184-8e7f23d0d773	0f8e0f55-b270-46d7-bf58-8831e5705cf8	jitsi_access	Appointment	e63e639a-e700-4ad3-803e-1ac0394290d4	\N	{"RoomName":"e63e639ae7004ad3803e1ac0394290d4","IsModerator":false,"Domain":"localhost:8443"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-05T15:38:53.7823068Z	2026-02-05T15:38:53.7823071Z	\N	\N	\N	\N
493b333f-8f20-4ff1-9370-87573a23461b	0f8e0f55-b270-46d7-bf58-8831e5705cf8	jitsi_access	Appointment	d9e50997-f8f1-45f2-9190-7f54269ce741	\N	{"RoomName":"d9e50997f8f145f291907f54269ce741","IsModerator":false,"Domain":"localhost:8443"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-05T15:54:02.1330744Z	2026-02-05T15:54:02.1330745Z	\N	\N	\N	\N
cd92893c-9378-4d95-9541-8fa4a6bc9349	dc42f275-da07-437e-9c47-32100563d610	login	User	dc42f275-da07-437e-9c47-32100563d610	\N	{"Email":"med_gt@telecuidar.com","LoginTime":"2026-02-05T16:02:14.6079184Z"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-05T16:02:14.6084987Z	2026-02-05T16:02:14.6084988Z	\N	\N	\N	\N
830b09ae-040a-4345-8094-1afd6b2c6e81	0f8e0f55-b270-46d7-bf58-8831e5705cf8	login	User	0f8e0f55-b270-46d7-bf58-8831e5705cf8	\N	{"Email":"enf_do@telecuidar.com","LoginTime":"2026-02-05T16:02:49.2290219Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-05T16:02:49.2291044Z	2026-02-05T16:02:49.2291045Z	\N	\N	\N	\N
13bf2012-5651-4304-a5a3-111f8c07ddef	0f8e0f55-b270-46d7-bf58-8831e5705cf8	jitsi_access	Appointment	e63e639a-e700-4ad3-803e-1ac0394290d4	\N	{"RoomName":"e63e639ae7004ad3803e1ac0394290d4","IsModerator":false,"Domain":"localhost:8443"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-05T16:03:01.2986448Z	2026-02-05T16:03:01.2986448Z	\N	\N	\N	\N
dc859cf7-28c6-4f6e-acfa-785031e66e02	dc42f275-da07-437e-9c47-32100563d610	jitsi_access	Appointment	e63e639a-e700-4ad3-803e-1ac0394290d4	\N	{"RoomName":"e63e639ae7004ad3803e1ac0394290d4","IsModerator":true,"Domain":"192.168.18.31:8443"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-05T16:03:25.0452475Z	2026-02-05T16:03:25.0452475Z	\N	\N	\N	\N
33806cd7-125e-47ea-99ae-dbcb45b5e3b9	dc42f275-da07-437e-9c47-32100563d610	jitsi_access	Appointment	e63e639a-e700-4ad3-803e-1ac0394290d4	\N	{"RoomName":"e63e639ae7004ad3803e1ac0394290d4","IsModerator":true,"Domain":"192.168.18.31:8443"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-05T16:42:51.2727029Z	2026-02-05T16:42:51.2727030Z	\N	\N	\N	\N
5fc4b2eb-b7c7-409f-b8d1-c1a1149b0b6b	dc42f275-da07-437e-9c47-32100563d610	login	User	dc42f275-da07-437e-9c47-32100563d610	\N	{"Email":"med_gt@telecuidar.com","LoginTime":"2026-02-05T17:27:23.4456649Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-05T17:27:23.4469220Z	2026-02-05T17:27:23.4469220Z	\N	\N	\N	\N
6fe4160e-8771-4e09-98d2-2dd16443d42a	dc42f275-da07-437e-9c47-32100563d610	login	User	dc42f275-da07-437e-9c47-32100563d610	\N	{"Email":"med_gt@telecuidar.com","LoginTime":"2026-02-05T17:51:34.7935585Z"}	127.0.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; pt-BR) WindowsPowerShell/5.1.26100.7462	2026-02-05T17:51:34.8064603Z	2026-02-05T17:51:34.8064608Z	\N	\N	\N	\N
de37ca8b-bdde-4d6e-8f85-a5257df683d2	dc42f275-da07-437e-9c47-32100563d610	login	User	dc42f275-da07-437e-9c47-32100563d610	\N	{"Email":"med_gt@telecuidar.com","LoginTime":"2026-02-05T17:51:52.538829Z"}	127.0.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; pt-BR) WindowsPowerShell/5.1.26100.7462	2026-02-05T17:51:52.5389872Z	2026-02-05T17:51:52.5389873Z	\N	\N	\N	\N
0b7b76ac-cc43-4237-b19b-60a64f5a84e4	dc42f275-da07-437e-9c47-32100563d610	login	User	dc42f275-da07-437e-9c47-32100563d610	\N	{"Email":"med_gt@telecuidar.com","LoginTime":"2026-02-05T17:52:06.4068463Z"}	127.0.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; pt-BR) WindowsPowerShell/5.1.26100.7462	2026-02-05T17:52:06.4069154Z	2026-02-05T17:52:06.4069155Z	\N	\N	\N	\N
e01c336f-b15b-42e5-b133-e58657d2ca38	0f8e0f55-b270-46d7-bf58-8831e5705cf8	login	User	0f8e0f55-b270-46d7-bf58-8831e5705cf8	\N	{"Email":"enf_do@telecuidar.com","LoginTime":"2026-02-05T23:30:49.7382133Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-05T23:30:49.7645964Z	2026-02-05T23:30:49.7645967Z	\N	\N	\N	\N
4373f48e-5532-4a96-bdb6-cb7a4e541148	c8d3e9ae-1b97-4758-8789-5ef40dd70abb	login	User	c8d3e9ae-1b97-4758-8789-5ef40dd70abb	\N	{"Email":"med_aj@telecuidar.com","LoginTime":"2026-02-05T23:34:38.538587Z"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-05T23:34:38.5635897Z	2026-02-05T23:34:38.5635900Z	\N	\N	\N	\N
87471cc6-d05a-4e2d-949b-6b1078265e42	0f8e0f55-b270-46d7-bf58-8831e5705cf8	jitsi_access	Appointment	e7459b24-c109-4fa0-a374-576312f67527	\N	{"RoomName":"e7459b24c1094fa0a374576312f67527","IsModerator":false,"Domain":"localhost:8443"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-05T23:35:51.4626516Z	2026-02-05T23:35:51.4626519Z	\N	\N	\N	\N
bdf8871b-9af1-4d0f-9420-8b7ac874e70a	c8d3e9ae-1b97-4758-8789-5ef40dd70abb	jitsi_access	Appointment	e7459b24-c109-4fa0-a374-576312f67527	\N	{"RoomName":"e7459b24c1094fa0a374576312f67527","IsModerator":true,"Domain":"192.168.18.31:8443"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-05T23:40:07.2410756Z	2026-02-05T23:40:07.2410757Z	\N	\N	\N	\N
684370e0-031c-4a21-8a01-523e17fcc0fd	0f8e0f55-b270-46d7-bf58-8831e5705cf8	login	User	0f8e0f55-b270-46d7-bf58-8831e5705cf8	\N	{"Email":"enf_do@telecuidar.com","LoginTime":"2026-02-06T01:35:52.0040964Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-06T01:35:52.0057822Z	2026-02-06T01:35:52.0057823Z	\N	\N	\N	\N
d88d3846-cf0b-4744-8ec0-d72c035924d0	0f8e0f55-b270-46d7-bf58-8831e5705cf8	jitsi_access	Appointment	aa4c6779-94be-4a1b-a674-636d6e44f978	\N	{"RoomName":"aa4c677994be4a1ba674636d6e44f978","IsModerator":false,"Domain":"localhost:8443"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-06T01:35:59.8085549Z	2026-02-06T01:35:59.8085550Z	\N	\N	\N	\N
ef047a99-bc1c-496c-96c8-a354e1da7083	0f8e0f55-b270-46d7-bf58-8831e5705cf8	login	User	0f8e0f55-b270-46d7-bf58-8831e5705cf8	\N	{"Email":"enf_do@telecuidar.com","LoginTime":"2026-02-06T05:29:12.702375Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-06T05:29:12.7043988Z	2026-02-06T05:29:12.7043989Z	\N	\N	\N	\N
be496f7d-bd0e-44ee-b1a1-9c95dcd4b6f2	0f8e0f55-b270-46d7-bf58-8831e5705cf8	jitsi_access	Appointment	97a70547-5fa9-420d-a634-f13730db5edd	\N	{"RoomName":"97a705475fa9420da634f13730db5edd","IsModerator":false,"Domain":"localhost:8443"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-06T05:54:51.1967035Z	2026-02-06T05:54:51.1967036Z	\N	\N	\N	\N
3123ed00-e96e-4d88-9a64-701eaa96a667	0f8e0f55-b270-46d7-bf58-8831e5705cf8	login	User	0f8e0f55-b270-46d7-bf58-8831e5705cf8	\N	{"Email":"enf_do@telecuidar.com","LoginTime":"2026-02-06T06:40:50.3757317Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-06T06:40:50.3854504Z	2026-02-06T06:40:50.3854505Z	\N	\N	\N	\N
5055b766-d76b-4e18-b75a-4fbf6e9e31c6	0f8e0f55-b270-46d7-bf58-8831e5705cf8	jitsi_access	Appointment	97a70547-5fa9-420d-a634-f13730db5edd	\N	{"RoomName":"97a705475fa9420da634f13730db5edd","IsModerator":false,"Domain":"localhost:8443"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-06T06:41:11.7586208Z	2026-02-06T06:41:11.7586209Z	\N	\N	\N	\N
6d3c8d95-7478-493e-b1ba-e230276e92ad	dc42f275-da07-437e-9c47-32100563d610	login	User	dc42f275-da07-437e-9c47-32100563d610	\N	{"Email":"med_gt@telecuidar.com","LoginTime":"2026-02-06T06:42:36.2591648Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-06T06:42:36.2600799Z	2026-02-06T06:42:36.2600801Z	\N	\N	\N	\N
6818b332-2363-4deb-98b1-f81aa2889241	dc42f275-da07-437e-9c47-32100563d610	jitsi_access	Appointment	97a70547-5fa9-420d-a634-f13730db5edd	\N	{"RoomName":"97a705475fa9420da634f13730db5edd","IsModerator":true,"Domain":"localhost:8443"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-06T06:42:58.2751070Z	2026-02-06T06:42:58.2751071Z	\N	\N	\N	\N
423b6601-818a-49c3-95b3-a716dde002fe	0f8e0f55-b270-46d7-bf58-8831e5705cf8	jitsi_access	Appointment	97a70547-5fa9-420d-a634-f13730db5edd	\N	{"RoomName":"97a705475fa9420da634f13730db5edd","IsModerator":false,"Domain":"localhost:8443"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-06T06:43:43.8229123Z	2026-02-06T06:43:43.8229126Z	\N	\N	\N	\N
1e745b45-2daf-4941-a069-ebdfdeee1f68	0f8e0f55-b270-46d7-bf58-8831e5705cf8	jitsi_access	Appointment	97a70547-5fa9-420d-a634-f13730db5edd	\N	{"RoomName":"97a705475fa9420da634f13730db5edd","IsModerator":false,"Domain":"localhost:8443"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-06T06:50:29.4634860Z	2026-02-06T06:50:29.4634861Z	\N	\N	\N	\N
82bf7428-785f-4c9b-b60a-5f2b60d6278f	dc42f275-da07-437e-9c47-32100563d610	jitsi_access	Appointment	97a70547-5fa9-420d-a634-f13730db5edd	\N	{"RoomName":"97a705475fa9420da634f13730db5edd","IsModerator":true,"Domain":"localhost:8443"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-06T06:50:32.5523593Z	2026-02-06T06:50:32.5523594Z	\N	\N	\N	\N
0fa2e050-9975-484d-bde1-970d83eefc9e	0f8e0f55-b270-46d7-bf58-8831e5705cf8	jitsi_access	Appointment	97a70547-5fa9-420d-a634-f13730db5edd	\N	{"RoomName":"97a705475fa9420da634f13730db5edd","IsModerator":false,"Domain":"localhost:8443"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-06T06:50:46.7411968Z	2026-02-06T06:50:46.7411969Z	\N	\N	\N	\N
3dcd75b5-387b-4409-8939-0b676cd06f13	0f8e0f55-b270-46d7-bf58-8831e5705cf8	jitsi_access	Appointment	97a70547-5fa9-420d-a634-f13730db5edd	\N	{"RoomName":"97a705475fa9420da634f13730db5edd","IsModerator":false,"Domain":"localhost:8443"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-06T06:51:10.3997334Z	2026-02-06T06:51:10.3997335Z	\N	\N	\N	\N
712ff168-2576-46ca-91e5-ddf46f1c4e4b	0f8e0f55-b270-46d7-bf58-8831e5705cf8	login	User	0f8e0f55-b270-46d7-bf58-8831e5705cf8	\N	{"Email":"enf_do@telecuidar.com","LoginTime":"2026-02-06T06:51:36.7490965Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-06T06:51:36.7492211Z	2026-02-06T06:51:36.7492212Z	\N	\N	\N	\N
c271b0d6-4215-462a-b80b-9d20e60b7014	0f8e0f55-b270-46d7-bf58-8831e5705cf8	jitsi_access	Appointment	97a70547-5fa9-420d-a634-f13730db5edd	\N	{"RoomName":"97a705475fa9420da634f13730db5edd","IsModerator":false,"Domain":"localhost:8443"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-06T06:51:50.2747468Z	2026-02-06T06:51:50.2747469Z	\N	\N	\N	\N
682e6308-4a3f-4d19-87ea-5e3aedc786e2	0f8e0f55-b270-46d7-bf58-8831e5705cf8	jitsi_access	Appointment	97a70547-5fa9-420d-a634-f13730db5edd	\N	{"RoomName":"97a705475fa9420da634f13730db5edd","IsModerator":false,"Domain":"localhost:8443"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-06T06:53:36.6693005Z	2026-02-06T06:53:36.6693005Z	\N	\N	\N	\N
39cb8a6e-b515-4c94-8745-8fecc4c1619f	dc42f275-da07-437e-9c47-32100563d610	login	User	dc42f275-da07-437e-9c47-32100563d610	\N	{"Email":"med_gt@telecuidar.com","LoginTime":"2026-02-06T06:54:29.6044011Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-06T06:54:29.6044688Z	2026-02-06T06:54:29.6044688Z	\N	\N	\N	\N
43afaa51-f206-42ee-a79a-8de5c1e995c3	dc42f275-da07-437e-9c47-32100563d610	jitsi_access	Appointment	97a70547-5fa9-420d-a634-f13730db5edd	\N	{"RoomName":"97a705475fa9420da634f13730db5edd","IsModerator":true,"Domain":"localhost:8443"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-06T06:54:33.2846648Z	2026-02-06T06:54:33.2846649Z	\N	\N	\N	\N
5df2de2f-a05c-4f0a-abb7-130d66f4762f	0f8e0f55-b270-46d7-bf58-8831e5705cf8	jitsi_access	Appointment	97a70547-5fa9-420d-a634-f13730db5edd	\N	{"RoomName":"97a705475fa9420da634f13730db5edd","IsModerator":false,"Domain":"localhost:8443"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-06T06:58:27.3370084Z	2026-02-06T06:58:27.3370085Z	\N	\N	\N	\N
565cba6a-7b28-4f06-a098-ca13ee550112	dc42f275-da07-437e-9c47-32100563d610	jitsi_access	Appointment	97a70547-5fa9-420d-a634-f13730db5edd	\N	{"RoomName":"97a705475fa9420da634f13730db5edd","IsModerator":true,"Domain":"localhost:8443"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-06T06:58:27.7668412Z	2026-02-06T06:58:27.7668413Z	\N	\N	\N	\N
1c7ec74c-017c-4b64-bcee-80b363ea7637	0f8e0f55-b270-46d7-bf58-8831e5705cf8	jitsi_access	Appointment	97a70547-5fa9-420d-a634-f13730db5edd	\N	{"RoomName":"97a705475fa9420da634f13730db5edd","IsModerator":false,"Domain":"localhost:8443"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-06T06:59:24.1879460Z	2026-02-06T06:59:24.1879461Z	\N	\N	\N	\N
a07250a4-fe8f-4c10-b0ae-6dd4029ef030	dc42f275-da07-437e-9c47-32100563d610	jitsi_access	Appointment	97a70547-5fa9-420d-a634-f13730db5edd	\N	{"RoomName":"97a705475fa9420da634f13730db5edd","IsModerator":true,"Domain":"localhost:8443"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-06T06:59:30.0509582Z	2026-02-06T06:59:30.0509591Z	\N	\N	\N	\N
3126a973-1ae2-4284-b72e-e78a29f6b1bb	0f8e0f55-b270-46d7-bf58-8831e5705cf8	jitsi_access	Appointment	97a70547-5fa9-420d-a634-f13730db5edd	\N	{"RoomName":"97a705475fa9420da634f13730db5edd","IsModerator":false,"Domain":"localhost:8443"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-06T07:03:51.4327897Z	2026-02-06T07:03:51.4327897Z	\N	\N	\N	\N
c00684fc-d391-432f-a5fe-4e95a9a90ad7	0f8e0f55-b270-46d7-bf58-8831e5705cf8	jitsi_access	Appointment	97a70547-5fa9-420d-a634-f13730db5edd	\N	{"RoomName":"97a705475fa9420da634f13730db5edd","IsModerator":false,"Domain":"localhost:8443"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-06T07:05:15.6119500Z	2026-02-06T07:05:15.6119501Z	\N	\N	\N	\N
77157f04-cd22-4427-be6f-7f3dac026996	0f8e0f55-b270-46d7-bf58-8831e5705cf8	jitsi_access	Appointment	97a70547-5fa9-420d-a634-f13730db5edd	\N	{"RoomName":"97a705475fa9420da634f13730db5edd","IsModerator":false,"Domain":"localhost:8443"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-06T07:09:16.5369132Z	2026-02-06T07:09:16.5369134Z	\N	\N	\N	\N
2b67aa67-721a-4654-9b5b-174de5123a80	dc42f275-da07-437e-9c47-32100563d610	jitsi_access	Appointment	97a70547-5fa9-420d-a634-f13730db5edd	\N	{"RoomName":"97a705475fa9420da634f13730db5edd","IsModerator":true,"Domain":"localhost:8443"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-06T07:14:10.8920948Z	2026-02-06T07:14:10.8920949Z	\N	\N	\N	\N
8ca3cd65-b518-4ec9-a478-192495c31de7	0f8e0f55-b270-46d7-bf58-8831e5705cf8	jitsi_access	Appointment	97a70547-5fa9-420d-a634-f13730db5edd	\N	{"RoomName":"97a705475fa9420da634f13730db5edd","IsModerator":false,"Domain":"localhost:8443"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-06T07:14:11.0146012Z	2026-02-06T07:14:11.0146013Z	\N	\N	\N	\N
2855ca29-c8a0-4473-b7c0-a06b5693bb88	dc42f275-da07-437e-9c47-32100563d610	jitsi_access	Appointment	97a70547-5fa9-420d-a634-f13730db5edd	\N	{"RoomName":"97a705475fa9420da634f13730db5edd","IsModerator":true,"Domain":"localhost:8443"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-06T07:14:32.3313011Z	2026-02-06T07:14:32.3313012Z	\N	\N	\N	\N
f67c63f8-4990-4fa5-ad76-26144ec8b3ab	0f8e0f55-b270-46d7-bf58-8831e5705cf8	jitsi_access	Appointment	97a70547-5fa9-420d-a634-f13730db5edd	\N	{"RoomName":"97a705475fa9420da634f13730db5edd","IsModerator":false,"Domain":"localhost:8443"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-06T07:14:32.6310378Z	2026-02-06T07:14:32.6310380Z	\N	\N	\N	\N
238d46cf-51a1-43c3-a048-4c013a52c15b	0f8e0f55-b270-46d7-bf58-8831e5705cf8	jitsi_access	Appointment	97a70547-5fa9-420d-a634-f13730db5edd	\N	{"RoomName":"97a705475fa9420da634f13730db5edd","IsModerator":false,"Domain":"localhost:8443"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-06T07:17:02.3214793Z	2026-02-06T07:17:02.3214793Z	\N	\N	\N	\N
44881827-1d66-4196-84cd-cd12a2bad00a	dc42f275-da07-437e-9c47-32100563d610	jitsi_access	Appointment	97a70547-5fa9-420d-a634-f13730db5edd	\N	{"RoomName":"97a705475fa9420da634f13730db5edd","IsModerator":true,"Domain":"localhost:8443"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-06T07:17:08.3949298Z	2026-02-06T07:17:08.3949300Z	\N	\N	\N	\N
2a99e468-9764-4151-984e-639fa7bd8603	dc42f275-da07-437e-9c47-32100563d610	jitsi_access	Appointment	97a70547-5fa9-420d-a634-f13730db5edd	\N	{"RoomName":"97a705475fa9420da634f13730db5edd","IsModerator":true,"Domain":"localhost:8443"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-06T07:27:05.4896713Z	2026-02-06T07:27:05.4896715Z	\N	\N	\N	\N
593584d4-0e86-47bb-991a-c16b6a285c95	0f8e0f55-b270-46d7-bf58-8831e5705cf8	jitsi_access	Appointment	97a70547-5fa9-420d-a634-f13730db5edd	\N	{"RoomName":"97a705475fa9420da634f13730db5edd","IsModerator":false,"Domain":"localhost:8443"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-06T07:27:05.7769018Z	2026-02-06T07:27:05.7769019Z	\N	\N	\N	\N
b7e98583-0e08-46a8-a42e-7344e09db0b4	0f8e0f55-b270-46d7-bf58-8831e5705cf8	jitsi_access	Appointment	97a70547-5fa9-420d-a634-f13730db5edd	\N	{"RoomName":"97a705475fa9420da634f13730db5edd","IsModerator":false,"Domain":"localhost:8443"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-06T07:33:37.7813281Z	2026-02-06T07:33:37.7813282Z	\N	\N	\N	\N
f2be8928-1545-438d-9052-a1a578fe6b9f	dc42f275-da07-437e-9c47-32100563d610	jitsi_access	Appointment	97a70547-5fa9-420d-a634-f13730db5edd	\N	{"RoomName":"97a705475fa9420da634f13730db5edd","IsModerator":true,"Domain":"localhost:8443"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-06T07:33:48.5030608Z	2026-02-06T07:33:48.5030609Z	\N	\N	\N	\N
\.


--
-- Data for Name: CboOccupations; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."CboOccupations" ("Id", "Code", "Name", "Family", "Subgroup", "AllowsTeleconsultation", "IsActive", "CreatedAt", "UpdatedAt") FROM stdin;
\.


--
-- Data for Name: DigitalCertificates; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."DigitalCertificates" ("Id", "UserId", "DisplayName", "Subject", "Issuer", "Thumbprint", "CpfFromCertificate", "NameFromCertificate", "ExpirationDate", "IssuedDate", "EncryptedPfxBase64", "QuickUseEnabled", "EncryptedPassword", "EncryptionIV", "IsActive", "LastUsedAt", "CreatedAt", "UpdatedAt") FROM stdin;
\.


--
-- Data for Name: ExamRequests; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."ExamRequests" ("Id", "AppointmentId", "ProfessionalId", "PatientId", "NomeExame", "CodigoExame", "Categoria", "Prioridade", "DataEmissao", "DataLimite", "IndicacaoClinica", "HipoteseDiagnostica", "Cid", "Observacoes", "InstrucoesPreparo", "DigitalSignature", "CertificateThumbprint", "CertificateSubject", "SignedAt", "DocumentHash", "SignedPdfBase64", "CreatedAt", "UpdatedAt") FROM stdin;
\.


--
-- Data for Name: Invites; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."Invites" ("Id", "Email", "Role", "SpecialtyId", "Token", "Status", "ExpiresAt", "CreatedBy", "CreatedAt", "AcceptedAt", "PrefilledName", "PrefilledLastName", "PrefilledCpf", "PrefilledPhone") FROM stdin;
\.


--
-- Data for Name: MedicalCertificates; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."MedicalCertificates" ("Id", "AppointmentId", "ProfessionalId", "PatientId", "Tipo", "DataEmissao", "DataInicio", "DataFim", "DiasAfastamento", "Cid", "Conteudo", "Observacoes", "DigitalSignature", "CertificateThumbprint", "CertificateSubject", "SignedAt", "DocumentHash", "SignedPdfBase64", "CreatedAt", "UpdatedAt") FROM stdin;
\.


--
-- Data for Name: MedicalReports; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."MedicalReports" ("Id", "AppointmentId", "ProfessionalId", "PatientId", "Tipo", "Titulo", "DataEmissao", "HistoricoClinico", "ExameFisico", "ExamesComplementares", "HipoteseDiagnostica", "Cid", "Conclusao", "Recomendacoes", "Observacoes", "DigitalSignature", "CertificateThumbprint", "CertificateSubject", "SignedAt", "DocumentHash", "SignedPdfBase64", "CreatedAt", "UpdatedAt") FROM stdin;
\.


--
-- Data for Name: Notifications; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."Notifications" ("Id", "UserId", "Title", "Message", "Type", "IsRead", "Link", "CreatedAt", "UpdatedAt") FROM stdin;
\.


--
-- Data for Name: PatientProfiles; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."PatientProfiles" ("Id", "UserId", "Cns", "SocialName", "Gender", "BirthDate", "MotherName", "FatherName", "Nationality", "ZipCode", "Address", "City", "State", "CreatedAt", "UpdatedAt") FROM stdin;
1c6f6da7-c789-469f-851d-6f865eee9d52	1b136568-233e-4201-9c43-f0445a6017b3	757372163159410	\N	M	1975-12-24T07:29:26.6881714-02:00	\N	\N	\N	\N	\N	\N	\N	2026-02-05T10:29:26.6881691Z	2026-02-05T10:29:26.6881692Z
1ce017d3-a8a5-4691-a77d-43bb31194ac6	454458dd-c79a-4fe1-8d7c-2e5d712ee871	795879920960951	\N	M	1966-05-03T07:29:26.6879779-03:00	\N	\N	\N	\N	\N	\N	\N	2026-02-05T10:29:26.6879548Z	2026-02-05T10:29:26.6879552Z
ac04af2d-1988-4635-a27f-95315d8dbf4c	62f70bc8-e96e-4308-bffc-15bcada66ed7	738766205122824	\N	M	1966-06-01T07:29:26.6882269-03:00	\N	\N	\N	\N	\N	\N	\N	2026-02-05T10:29:26.6882247Z	2026-02-05T10:29:26.6882248Z
ed8a55dd-47d7-4e62-887a-c431c383c279	1a25bc58-0f72-4f59-a892-0d6ee51f0c07	719246927773179	\N	F	1967-03-20T07:29:26.6881161-03:00	\N	\N	\N	\N	\N	\N	\N	2026-02-05T10:29:26.6881130Z	2026-02-05T10:29:26.6881131Z
ef441f51-adc0-4f28-a77f-d32baaeda868	268323db-7e11-42d4-85ee-7d4337798131	720540713855850	\N	M	1981-02-16T07:29:26.6576973-03:00	\N	\N	\N	\N	\N	\N	\N	2026-02-05T10:29:26.6575488Z	2026-02-05T10:29:26.6575490Z
\.


--
-- Data for Name: Prescriptions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."Prescriptions" ("Id", "AppointmentId", "ProfessionalId", "PatientId", "ItemsJson", "DigitalSignature", "CertificateThumbprint", "CertificateSubject", "SignedAt", "DocumentHash", "SignedPdfBase64", "CreatedAt", "UpdatedAt") FROM stdin;
\.


--
-- Data for Name: ProfessionalCouncils; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."ProfessionalCouncils" ("Id", "Acronym", "Name", "Category", "IsActive", "CreatedAt", "UpdatedAt") FROM stdin;
11111111-1111-1111-1111-111111111111	CRM	Conselho Regional de Medicina	Medicina	1	2026-01-01	2026-01-01
22222222-2222-2222-2222-222222222222	COREN	Conselho Regional de Enfermagem	Enfermagem	1	2026-01-01	2026-01-01
\.


--
-- Data for Name: ProfessionalProfiles; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."ProfessionalProfiles" ("Id", "UserId", "Crm", "Cbo", "SpecialtyId", "Gender", "BirthDate", "Nationality", "ZipCode", "Address", "City", "State", "CreatedAt", "UpdatedAt", "CboOccupationId", "CouncilId", "CouncilRegistration", "CouncilState") FROM stdin;
3cd63ba7-2a5c-468e-8a0a-b724f5547840	c8d3e9ae-1b97-4758-8789-5ef40dd70abb	\N	\N	5b4fc232-61f3-4066-912d-d9367d818798	M	1986-09-23T07:29:26.5281665-03:00	\N	\N	\N	\N	\N	2026-02-05T10:29:26.5276553Z	2026-02-05T10:29:26.5276556Z	\N	11111111-1111-1111-1111-111111111111	120410	MG
73478441-9864-4148-b4a2-a77d2805907f	321c02a6-3abb-4158-93e9-41ce25573586	\N	\N	ae03858a-9cb0-4361-8857-857435949d82	M	1981-04-17T07:29:26.5812295-03:00	\N	\N	\N	\N	\N	2026-02-05T10:29:26.5812266Z	2026-02-05T10:29:26.5812267Z	\N	11111111-1111-1111-1111-111111111111	199003	MG
9eaf41ee-bcef-4635-b4bb-67487763b121	dc42f275-da07-437e-9c47-32100563d610	\N	\N	f5196497-9f26-4f98-a240-1bb0c8c60639	M	1989-10-17T07:29:26.5809322-03:00	\N	\N	\N	\N	\N	2026-02-05T10:29:26.5809206Z	2026-02-05T10:29:26.5809209Z	\N	11111111-1111-1111-1111-111111111111	137003	MG
b4dd2938-434a-463b-8413-77ef7b077e60	09c33afc-d053-4f1d-946d-aba173642b36	\N	\N	8ee8d058-d70b-4bd0-916f-5dbe9621caf5	F	1986-05-17T07:29:26.5811349-03:00	\N	\N	\N	\N	\N	2026-02-05T10:29:26.5811314Z	2026-02-05T10:29:26.5811315Z	\N	11111111-1111-1111-1111-111111111111	165912	MG
bd903631-2b7b-4f72-a4e3-f1488489abc2	f7fa3199-a452-4244-aabd-4fff524edbd8	\N	\N	a3e0437e-76c6-478a-a465-1d1b81e8bbb9	M	1987-04-19T07:29:26.5813172-03:00	\N	\N	\N	\N	\N	2026-02-05T10:29:26.5813139Z	2026-02-05T10:29:26.5813140Z	\N	11111111-1111-1111-1111-111111111111	128489	MG
\.


--
-- Data for Name: ScheduleBlocks; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."ScheduleBlocks" ("Id", "ProfessionalId", "Type", "Date", "StartDate", "EndDate", "Reason", "Status", "ApprovedBy", "ApprovedAt", "RejectionReason", "CreatedAt", "UpdatedAt") FROM stdin;
\.


--
-- Data for Name: Schedules; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."Schedules" ("Id", "ProfessionalId", "GlobalConfigJson", "DaysConfigJson", "ValidityStartDate", "ValidityEndDate", "IsActive", "CreatedAt", "UpdatedAt") FROM stdin;
70da12bc-a616-4b6d-a688-f696a8457d72	c8d3e9ae-1b97-4758-8789-5ef40dd70abb	{\r\n            "TimeRange": {\r\n                "StartTime": "08:00",\r\n                "EndTime": "18:00"\r\n            },\r\n            "ConsultationDuration": 30,\r\n            "IntervalBetweenConsultations": 0\r\n        }	[\r\n            {"Day": "Monday", "IsWorking": true, "Customized": false},\r\n            {"Day": "Tuesday", "IsWorking": true, "Customized": false},\r\n            {"Day": "Wednesday", "IsWorking": true, "Customized": false},\r\n            {"Day": "Thursday", "IsWorking": true, "Customized": false},\r\n            {"Day": "Friday", "IsWorking": true, "Customized": false},\r\n            {"Day": "Saturday", "IsWorking": false, "Customized": false},\r\n            {"Day": "Sunday", "IsWorking": false, "Customized": false}\r\n        ]	2026-02-01T00:00:00.0000000	2026-03-31T00:00:00.0000000	1	2026-02-05T10:29:26.7039922Z	2026-02-05T10:29:26.7039924Z
a33816b2-c82a-4de0-9eb1-06097e7b94d5	321c02a6-3abb-4158-93e9-41ce25573586	{\r\n            "TimeRange": {\r\n                "StartTime": "08:00",\r\n                "EndTime": "18:00"\r\n            },\r\n            "ConsultationDuration": 30,\r\n            "IntervalBetweenConsultations": 0\r\n        }	[\r\n            {"Day": "Monday", "IsWorking": true, "Customized": false},\r\n            {"Day": "Tuesday", "IsWorking": true, "Customized": false},\r\n            {"Day": "Wednesday", "IsWorking": true, "Customized": false},\r\n            {"Day": "Thursday", "IsWorking": true, "Customized": false},\r\n            {"Day": "Friday", "IsWorking": true, "Customized": false},\r\n            {"Day": "Saturday", "IsWorking": false, "Customized": false},\r\n            {"Day": "Sunday", "IsWorking": false, "Customized": false}\r\n        ]	2026-02-01T00:00:00.0000000	2026-03-31T00:00:00.0000000	1	2026-02-05T10:29:26.7242307Z	2026-02-05T10:29:26.7242311Z
cb4b2a51-9650-4328-b020-499eb277b9f7	dc42f275-da07-437e-9c47-32100563d610	{\r\n            "TimeRange": {\r\n                "StartTime": "08:00",\r\n                "EndTime": "18:00"\r\n            },\r\n            "ConsultationDuration": 30,\r\n            "IntervalBetweenConsultations": 0\r\n        }	[\r\n            {"Day": "Monday", "IsWorking": true, "Customized": false},\r\n            {"Day": "Tuesday", "IsWorking": true, "Customized": false},\r\n            {"Day": "Wednesday", "IsWorking": true, "Customized": false},\r\n            {"Day": "Thursday", "IsWorking": true, "Customized": false},\r\n            {"Day": "Friday", "IsWorking": true, "Customized": false},\r\n            {"Day": "Saturday", "IsWorking": false, "Customized": false},\r\n            {"Day": "Sunday", "IsWorking": false, "Customized": false}\r\n        ]	2026-02-01T00:00:00.0000000	2026-03-31T00:00:00.0000000	1	2026-02-05T10:29:26.7236406Z	2026-02-05T10:29:26.7236410Z
e01fe4fc-4682-4819-9527-73f46228a908	09c33afc-d053-4f1d-946d-aba173642b36	{\r\n            "TimeRange": {\r\n                "StartTime": "08:00",\r\n                "EndTime": "18:00"\r\n            },\r\n            "ConsultationDuration": 30,\r\n            "IntervalBetweenConsultations": 0\r\n        }	[\r\n            {"Day": "Monday", "IsWorking": true, "Customized": false},\r\n            {"Day": "Tuesday", "IsWorking": true, "Customized": false},\r\n            {"Day": "Wednesday", "IsWorking": true, "Customized": false},\r\n            {"Day": "Thursday", "IsWorking": true, "Customized": false},\r\n            {"Day": "Friday", "IsWorking": true, "Customized": false},\r\n            {"Day": "Saturday", "IsWorking": false, "Customized": false},\r\n            {"Day": "Sunday", "IsWorking": false, "Customized": false}\r\n        ]	2026-02-01T00:00:00.0000000	2026-03-31T00:00:00.0000000	1	2026-02-05T10:29:26.7239901Z	2026-02-05T10:29:26.7239906Z
f3a8277e-14cf-4dc1-b9bd-541798a56933	f7fa3199-a452-4244-aabd-4fff524edbd8	{\r\n            "TimeRange": {\r\n                "StartTime": "08:00",\r\n                "EndTime": "18:00"\r\n            },\r\n            "ConsultationDuration": 30,\r\n            "IntervalBetweenConsultations": 0\r\n        }	[\r\n            {"Day": "Monday", "IsWorking": true, "Customized": false},\r\n            {"Day": "Tuesday", "IsWorking": true, "Customized": false},\r\n            {"Day": "Wednesday", "IsWorking": true, "Customized": false},\r\n            {"Day": "Thursday", "IsWorking": true, "Customized": false},\r\n            {"Day": "Friday", "IsWorking": true, "Customized": false},\r\n            {"Day": "Saturday", "IsWorking": false, "Customized": false},\r\n            {"Day": "Sunday", "IsWorking": false, "Customized": false}\r\n        ]	2026-02-01T00:00:00.0000000	2026-03-31T00:00:00.0000000	1	2026-02-05T10:29:26.7245805Z	2026-02-05T10:29:26.7245808Z
\.


--
-- Data for Name: SigtapProcedures; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."SigtapProcedures" ("Id", "Code", "Name", "Description", "Complexity", "GroupCode", "GroupName", "SubgroupCode", "SubgroupName", "AuthorizedCbosJson", "Value", "AllowsTelemedicine", "IsActive", "StartCompetency", "EndCompetency", "CreatedAt", "UpdatedAt") FROM stdin;
\.


--
-- Data for Name: Specialties; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."Specialties" ("Id", "Name", "Description", "Status", "CustomFieldsJson", "CreatedAt", "UpdatedAt") FROM stdin;
5b4fc232-61f3-4066-912d-d9367d818798	Psiquiatria	Especialidade m├®dica dedicada ao diagn├│stico, tratamento e preven├º├úo de transtornos mentais, emocionais e comportamentais.	0	[\r\n        {"name":"Hist├│rico de Transtornos","type":"textarea","required":true,"description":"Descreva hist├│rico de transtornos mentais","order":1},\r\n        {"name":"Uso de Medica├º├úo Psiqui├ítrica","type":"radio","required":true,"description":"Faz uso de medica├º├úo psiqui├ítrica?","options":["Sim","N├úo"],"order":2},\r\n        {"name":"Medicamentos em Uso","type":"textarea","required":false,"description":"Liste os medicamentos psiqui├ítricos em uso","order":3},\r\n        {"name":"Idea├º├úo Suicida","type":"radio","required":true,"description":"Apresenta ou apresentou idea├º├úo suicida?","options":["Sim, atualmente","Sim, no passado","N├úo"],"order":4},\r\n        {"name":"Qualidade do Sono","type":"select","required":true,"description":"Como est├í a qualidade do sono?","options":["Boa","Regular","Ruim","Ins├┤nia"],"order":5},\r\n        {"name":"N├¡vel de Ansiedade (0-10)","type":"number","required":false,"description":"Avalie o n├¡vel de ansiedade de 0 a 10","order":6},\r\n        {"name":"Hist├│rico Familiar","type":"textarea","required":false,"description":"Hist├│rico familiar de transtornos mentais","order":7}\r\n    ]	2026-02-04T22:20:01.8589986Z	2026-02-04T22:20:01.8589987Z
f5196497-9f26-4f98-a240-1bb0c8c60639	Dermatologia	Especialidade m├®dica dedicada ao diagn├│stico e tratamento de doen├ºas da pele, cabelos, unhas e mucosas.	0	[\r\n        {"name":"Tipo de Pele","type":"select","required":true,"description":"Tipo de pele do paciente","options":["Normal","Seca","Oleosa","Mista","Sens├¡vel"],"order":1},\r\n        {"name":"Localiza├º├úo da Les├úo","type":"textarea","required":false,"description":"Descreva a localiza├º├úo das les├Áes","order":2},\r\n        {"name":"Tempo de Evolu├º├úo","type":"text","required":false,"description":"H├í quanto tempo apresenta as les├Áes?","order":3},\r\n        {"name":"Coceira","type":"radio","required":true,"description":"Apresenta coceira?","options":["Sim","N├úo"],"order":4},\r\n        {"name":"Exposi├º├úo Solar","type":"select","required":true,"description":"N├¡vel de exposi├º├úo solar","options":["Baixa","Moderada","Alta","Muito Alta"],"order":5},\r\n        {"name":"Uso de Protetor Solar","type":"radio","required":true,"description":"Usa protetor solar regularmente?","options":["Sim","N├úo","├Çs vezes"],"order":6},\r\n        {"name":"Alergias Conhecidas","type":"textarea","required":false,"description":"Liste alergias conhecidas","order":7}\r\n    ]	2026-02-04T22:20:02.0442405Z	2026-02-04T22:20:02.0442406Z
8ee8d058-d70b-4bd0-916f-5dbe9621caf5	Pediatria	Especialidade m├®dica dedicada ao cuidado integral da sa├║de de crian├ºas e adolescentes, desde o nascimento at├® os 18 anos.	0	[\r\n        {"name":"Idade da Crian├ºa","type":"text","required":true,"description":"Idade (anos e meses)","order":1},\r\n        {"name":"Peso (kg)","type":"number","required":true,"description":"Peso em quilogramas","order":2},\r\n        {"name":"Altura (cm)","type":"number","required":true,"description":"Altura em cent├¡metros","order":3},\r\n        {"name":"Vacinas em Dia","type":"radio","required":true,"description":"Cart├úo de vacinas est├í em dia?","options":["Sim","N├úo","N├úo sei"],"order":4},\r\n        {"name":"Amamenta├º├úo","type":"select","required":false,"description":"Situa├º├úo da amamenta├º├úo","options":["N├úo se aplica","Exclusiva","Mista","N├úo amamenta"],"order":5},\r\n        {"name":"Desenvolvimento Motor","type":"select","required":true,"description":"Desenvolvimento motor adequado para idade?","options":["Adequado","Atrasado","Avan├ºado"],"order":6},\r\n        {"name":"Alergias Alimentares","type":"textarea","required":false,"description":"Liste alergias alimentares conhecidas","order":7},\r\n        {"name":"Frequenta Escola/Creche","type":"radio","required":false,"description":"A crian├ºa frequenta escola ou creche?","options":["Sim","N├úo"],"order":8}\r\n    ]	2026-02-04T22:20:02.0521964Z	2026-02-04T22:20:02.0521964Z
ae03858a-9cb0-4361-8857-857435949d82	Cardiologia	Especialidade m├®dica dedicada ao diagn├│stico e tratamento de doen├ºas do cora├º├úo e do sistema circulat├│rio.	0	[\r\n        {"name":"Hist├│rico de Infarto","type":"checkbox","required":true,"description":"Paciente j├í teve infarto do mioc├írdio?","order":1},\r\n        {"name":"Press├úo Arterial Sist├│lica","type":"number","required":true,"description":"Press├úo arterial sist├│lica em mmHg","defaultValue":"120","order":2},\r\n        {"name":"Press├úo Arterial Diast├│lica","type":"number","required":true,"description":"Press├úo arterial diast├│lica em mmHg","defaultValue":"80","order":3},\r\n        {"name":"Frequ├¬ncia Card├¡aca","type":"number","required":true,"description":"Batimentos por minuto em repouso","order":4},\r\n        {"name":"Uso de Marca-passo","type":"radio","required":true,"description":"Paciente faz uso de marca-passo?","options":["Sim","N├úo"],"order":5},\r\n        {"name":"Tipo de Dor Tor├ícica","type":"select","required":false,"description":"Caso apresente dor tor├ícica, qual o tipo?","options":["N├úo apresenta","Dor em aperto","Dor em queima├º├úo","Dor em pontada","Dor irradiada"],"order":6},\r\n        {"name":"Medicamentos Cardiovasculares","type":"textarea","required":false,"description":"Liste os medicamentos em uso para o cora├º├úo","order":7},\r\n        {"name":"Data ├Ültimo ECG","type":"date","required":false,"description":"Data do ├║ltimo eletrocardiograma realizado","order":8}\r\n    ]	2026-02-04T22:20:02.0597966Z	2026-02-04T22:20:02.0597967Z
a3e0437e-76c6-478a-a465-1d1b81e8bbb9	Neurologia	Especialidade m├®dica dedicada ao diagn├│stico e tratamento de doen├ºas do sistema nervoso central e perif├®rico.	0	[\r\n        {"name":"Tipo de Cefaleia","type":"select","required":false,"description":"Tipo de dor de cabe├ºa","options":["N├úo apresenta","Tensional","Enxaqueca","Em salvas","Outros"],"order":1},\r\n        {"name":"Frequ├¬ncia das Crises","type":"text","required":false,"description":"Quantas vezes por semana/m├¬s?","order":2},\r\n        {"name":"Hist├│rico de AVC","type":"radio","required":true,"description":"J├í teve AVC?","options":["Sim","N├úo"],"order":3},\r\n        {"name":"Convuls├Áes","type":"radio","required":true,"description":"Apresenta ou apresentou convuls├Áes?","options":["Sim","N├úo"],"order":4},\r\n        {"name":"Altera├º├Áes de Mem├│ria","type":"select","required":true,"description":"Apresenta altera├º├Áes de mem├│ria?","options":["N├úo","Leves","Moderadas","Graves"],"order":5},\r\n        {"name":"Formigamento/Dorm├¬ncia","type":"textarea","required":false,"description":"Descreva localiza├º├úo de formigamento ou dorm├¬ncia","order":6},\r\n        {"name":"Medicamentos Neurol├│gicos","type":"textarea","required":false,"description":"Liste medicamentos neurol├│gicos em uso","order":7},\r\n        {"name":"Exames de Imagem Recentes","type":"textarea","required":false,"description":"Resson├óncia, tomografia realizados recentemente?","order":8}\r\n    ]	2026-02-04T22:20:02.0666463Z	2026-02-04T22:20:02.0666463Z
\.


--
-- Data for Name: Users; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."Users" ("Id", "Email", "PasswordHash", "Name", "LastName", "Cpf", "Phone", "Avatar", "Role", "Status", "EmailVerified", "EmailVerificationToken", "EmailVerificationTokenExpiry", "PendingEmail", "PendingEmailToken", "PendingEmailTokenExpiry", "PasswordResetToken", "PasswordResetTokenExpiry", "RefreshToken", "RefreshTokenExpiry", "CreatedAt", "UpdatedAt") FROM stdin;
09c33afc-d053-4f1d-946d-aba173642b36	med_do@telecuidar.com	$2a$12$gxgsTSicLFvsICPeX8JgU.i2F1t4fj0KoHX.2EgO6FoYsrVpj/2A.	Daniela	Ochoa	90000000002	11900000002	\N	1	0	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-02-05T10:29:26.4183784Z	2026-02-05T10:29:26.4183789Z
321c02a6-3abb-4158-93e9-41ce25573586	med_dc@telecuidar.com	$2a$12$gxgsTSicLFvsICPeX8JgU.i2F1t4fj0KoHX.2EgO6FoYsrVpj/2A.	Daniel	Carrara	90000000003	11900000003	\N	1	0	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-02-05T10:29:26.4344530Z	2026-02-05T10:29:26.4344534Z
f7fa3199-a452-4244-aabd-4fff524edbd8	med_ca@telecuidar.com	$2a$12$gxgsTSicLFvsICPeX8JgU.i2F1t4fj0KoHX.2EgO6FoYsrVpj/2A.	Cl├íudio	Amantino	90000000004	11900000004	\N	1	0	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-02-05T10:29:26.4695306Z	2026-02-05T10:29:26.4695312Z
0241d491-84ef-48fb-82f8-f4cc40413164	enf_gt@telecuidar.com	$2a$12$gxgsTSicLFvsICPeX8JgU.i2F1t4fj0KoHX.2EgO6FoYsrVpj/2A.	Geraldo	Tadeu	90000000006	11900000006	\N	3	0	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-02-05T10:29:26.6065700Z	2026-02-05T10:29:26.6065702Z
05c4dfd6-4aa6-423b-94fb-8abd4d427676	enf_aj@telecuidar.com	$2a$12$gxgsTSicLFvsICPeX8JgU.i2F1t4fj0KoHX.2EgO6FoYsrVpj/2A.	Ant├┤nio	Jorge	90000000005	11900000005	\N	3	0	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-02-05T10:29:26.6061868Z	2026-02-05T10:29:26.6061871Z
3ef14a2b-a524-4d2c-8208-e4ba255b6a64	enf_ca@telecuidar.com	$2a$12$gxgsTSicLFvsICPeX8JgU.i2F1t4fj0KoHX.2EgO6FoYsrVpj/2A.	Cl├íudio	Amantino	90000000009	11900000009	\N	3	0	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-02-05T10:29:26.6074655Z	2026-02-05T10:29:26.6074658Z
f32bfa79-f8b7-4f5d-896b-9d3c61c839eb	enf_dc@telecuidar.com	$2a$12$gxgsTSicLFvsICPeX8JgU.i2F1t4fj0KoHX.2EgO6FoYsrVpj/2A.	Daniel	Carrara	90000000008	11900000008	\N	3	0	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-02-05T10:29:26.6070424Z	2026-02-05T10:29:26.6070426Z
3c914e12-6305-47b2-b0be-d670f2c0d86a	adm_aj@telecuidar.com	$2a$12$gxgsTSicLFvsICPeX8JgU.i2F1t4fj0KoHX.2EgO6FoYsrVpj/2A.	Ant├┤nio	Jorge	90000000010	11900000010	\N	2	0	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-02-05T10:29:26.6153259Z	2026-02-05T10:29:26.6153260Z
dbf15ca7-1ce0-4521-b773-c55f55c4e1b3	adm_ca@telecuidar.com	$2a$12$gxgsTSicLFvsICPeX8JgU.i2F1t4fj0KoHX.2EgO6FoYsrVpj/2A.	Cl├íudio	Amantino	90000000014	11900000014	\N	2	0	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-02-05T10:29:26.6163630Z	2026-02-05T10:29:26.6163632Z
e43ef752-e1a3-4981-95f1-86db1b72b13c	adm_dc@telecuidar.com	$2a$12$gxgsTSicLFvsICPeX8JgU.i2F1t4fj0KoHX.2EgO6FoYsrVpj/2A.	Daniel	Carrara	90000000013	11900000013	\N	2	0	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-02-05T10:29:26.6162173Z	2026-02-05T10:29:26.6162174Z
f22e01aa-fbe5-4c1f-bfc7-f4770128b296	adm_do@telecuidar.com	$2a$12$gxgsTSicLFvsICPeX8JgU.i2F1t4fj0KoHX.2EgO6FoYsrVpj/2A.	Daniela	Ochoa	90000000012	11900000012	\N	2	0	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-02-05T10:29:26.6160603Z	2026-02-05T10:29:26.6160604Z
fac3df3c-ba6a-4b8e-8b64-501c2f094141	adm_gt@telecuidar.com	$2a$12$gxgsTSicLFvsICPeX8JgU.i2F1t4fj0KoHX.2EgO6FoYsrVpj/2A.	Geraldo	Tadeu	90000000011	11900000011	\N	2	0	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-02-05T10:29:26.6158314Z	2026-02-05T10:29:26.6158315Z
ae486681-c8b8-4319-b1a3-a56e9ecf8c2e	rec_ma@telecuidar.com	$2a$12$gxgsTSicLFvsICPeX8JgU.i2F1t4fj0KoHX.2EgO6FoYsrVpj/2A.	Maria	Atendimento	90000000015	11900000015	\N	4	0	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-02-05T10:29:26.6251771Z	2026-02-05T10:29:26.6251772Z
1a25bc58-0f72-4f59-a892-0d6ee51f0c07	pac_do@telecuidar.com	$2a$12$gxgsTSicLFvsICPeX8JgU.i2F1t4fj0KoHX.2EgO6FoYsrVpj/2A.	Daniela	Ochoa	90000000018	11900000018	\N	0	0	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-02-05T10:29:26.6300939Z	2026-02-05T10:29:26.6300943Z
1b136568-233e-4201-9c43-f0445a6017b3	pac_dc@telecuidar.com	$2a$12$gxgsTSicLFvsICPeX8JgU.i2F1t4fj0KoHX.2EgO6FoYsrVpj/2A.	Daniel	Carrara	90000000019	11900000019	\N	0	0	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-02-05T10:29:26.6303701Z	2026-02-05T10:29:26.6303704Z
268323db-7e11-42d4-85ee-7d4337798131	pac_aj@telecuidar.com	$2a$12$gxgsTSicLFvsICPeX8JgU.i2F1t4fj0KoHX.2EgO6FoYsrVpj/2A.	Ant├┤nio	Jorge	90000000016	11900000016	\N	0	0	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-02-05T10:29:26.6293830Z	2026-02-05T10:29:26.6293832Z
454458dd-c79a-4fe1-8d7c-2e5d712ee871	pac_gt@telecuidar.com	$2a$12$gxgsTSicLFvsICPeX8JgU.i2F1t4fj0KoHX.2EgO6FoYsrVpj/2A.	Geraldo	Tadeu	90000000017	11900000017	\N	0	0	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-02-05T10:29:26.6296758Z	2026-02-05T10:29:26.6296760Z
62f70bc8-e96e-4308-bffc-15bcada66ed7	pac_ca@telecuidar.com	$2a$12$gxgsTSicLFvsICPeX8JgU.i2F1t4fj0KoHX.2EgO6FoYsrVpj/2A.	Cl├íudio	Amantino	90000000020	11900000020	\N	0	0	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-02-05T10:29:26.6307363Z	2026-02-05T10:29:26.6307366Z
c8d3e9ae-1b97-4758-8789-5ef40dd70abb	med_aj@telecuidar.com	$2a$12$gxgsTSicLFvsICPeX8JgU.i2F1t4fj0KoHX.2EgO6FoYsrVpj/2A.	Ant├┤nio	Jorge	90000000000	11900000000	\N	1	0	1	\N	\N	\N	\N	\N	\N	\N	27/60ACeZ8IbWBZKQMqJl4MubBhp2YZqQOfQ7NPFzV4=	2026-02-06T23:34:38.1846958Z	2026-02-05T10:29:26.3478973Z	2026-02-05T23:34:38.2265780Z
0f8e0f55-b270-46d7-bf58-8831e5705cf8	enf_do@telecuidar.com	$2a$12$gxgsTSicLFvsICPeX8JgU.i2F1t4fj0KoHX.2EgO6FoYsrVpj/2A.	Daniela	Ochoa	90000000007	11900000007	\N	3	0	1	\N	\N	\N	\N	\N	\N	\N	6WvlezfE0kijVkgkQGZeqNXvcy6n/5pwczEFtn7enm4=	2026-02-07T06:51:36.7401049Z	2026-02-05T10:29:26.6068014Z	2026-02-06T06:51:36.7402133Z
dc42f275-da07-437e-9c47-32100563d610	med_gt@telecuidar.com	$2a$12$gxgsTSicLFvsICPeX8JgU.i2F1t4fj0KoHX.2EgO6FoYsrVpj/2A.	Geraldo	Tadeu	90000000001	11900000001	\N	1	0	1	\N	\N	\N	\N	\N	\N	\N	NtnPbQ7Zcxgdvk9+LeoxvvKocv9kVcBAZZaCql5n8Kw=	2026-02-07T06:54:29.5955861Z	2026-02-05T10:29:26.3908697Z	2026-02-06T06:54:29.5956721Z
\.


--
-- Data for Name: __EFMigrationsHistory; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."__EFMigrationsHistory" ("MigrationId", "ProductVersion") FROM stdin;
20260102213207_InitialCreate	9.0.0
20260114115742_AddProfessionalCouncilsAndAuditFields	9.0.0
20260201000000_AddReceptionistAndWaitingList	8.0.0
20260202000000_AddSpontaneousDemandFields	8.0.0
\.


--
-- Name: Appointments PK_Appointments; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Appointments"
    ADD CONSTRAINT "PK_Appointments" PRIMARY KEY ("Id");


--
-- Name: Attachments PK_Attachments; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Attachments"
    ADD CONSTRAINT "PK_Attachments" PRIMARY KEY ("Id");


--
-- Name: AuditLogs PK_AuditLogs; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."AuditLogs"
    ADD CONSTRAINT "PK_AuditLogs" PRIMARY KEY ("Id");


--
-- Name: CboOccupations PK_CboOccupations; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."CboOccupations"
    ADD CONSTRAINT "PK_CboOccupations" PRIMARY KEY ("Id");


--
-- Name: DigitalCertificates PK_DigitalCertificates; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."DigitalCertificates"
    ADD CONSTRAINT "PK_DigitalCertificates" PRIMARY KEY ("Id");


--
-- Name: ExamRequests PK_ExamRequests; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."ExamRequests"
    ADD CONSTRAINT "PK_ExamRequests" PRIMARY KEY ("Id");


--
-- Name: Invites PK_Invites; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Invites"
    ADD CONSTRAINT "PK_Invites" PRIMARY KEY ("Id");


--
-- Name: MedicalCertificates PK_MedicalCertificates; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."MedicalCertificates"
    ADD CONSTRAINT "PK_MedicalCertificates" PRIMARY KEY ("Id");


--
-- Name: MedicalReports PK_MedicalReports; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."MedicalReports"
    ADD CONSTRAINT "PK_MedicalReports" PRIMARY KEY ("Id");


--
-- Name: Notifications PK_Notifications; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Notifications"
    ADD CONSTRAINT "PK_Notifications" PRIMARY KEY ("Id");


--
-- Name: PatientProfiles PK_PatientProfiles; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."PatientProfiles"
    ADD CONSTRAINT "PK_PatientProfiles" PRIMARY KEY ("Id");


--
-- Name: Prescriptions PK_Prescriptions; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Prescriptions"
    ADD CONSTRAINT "PK_Prescriptions" PRIMARY KEY ("Id");


--
-- Name: ProfessionalCouncils PK_ProfessionalCouncils; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."ProfessionalCouncils"
    ADD CONSTRAINT "PK_ProfessionalCouncils" PRIMARY KEY ("Id");


--
-- Name: ProfessionalProfiles PK_ProfessionalProfiles; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."ProfessionalProfiles"
    ADD CONSTRAINT "PK_ProfessionalProfiles" PRIMARY KEY ("Id");


--
-- Name: ScheduleBlocks PK_ScheduleBlocks; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."ScheduleBlocks"
    ADD CONSTRAINT "PK_ScheduleBlocks" PRIMARY KEY ("Id");


--
-- Name: Schedules PK_Schedules; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Schedules"
    ADD CONSTRAINT "PK_Schedules" PRIMARY KEY ("Id");


--
-- Name: SigtapProcedures PK_SigtapProcedures; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."SigtapProcedures"
    ADD CONSTRAINT "PK_SigtapProcedures" PRIMARY KEY ("Id");


--
-- Name: Specialties PK_Specialties; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Specialties"
    ADD CONSTRAINT "PK_Specialties" PRIMARY KEY ("Id");


--
-- Name: Users PK_Users; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "PK_Users" PRIMARY KEY ("Id");


--
-- Name: __EFMigrationsHistory PK___EFMigrationsHistory; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."__EFMigrationsHistory"
    ADD CONSTRAINT "PK___EFMigrationsHistory" PRIMARY KEY ("MigrationId");


--
-- Name: IX_Appointments_PatientId; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IX_Appointments_PatientId" ON public."Appointments" USING btree ("PatientId");


--
-- Name: IX_Appointments_ProfessionalId; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IX_Appointments_ProfessionalId" ON public."Appointments" USING btree ("ProfessionalId");


--
-- Name: IX_Appointments_SpecialtyId; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IX_Appointments_SpecialtyId" ON public."Appointments" USING btree ("SpecialtyId");


--
-- Name: IX_Attachments_AppointmentId; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IX_Attachments_AppointmentId" ON public."Attachments" USING btree ("AppointmentId");


--
-- Name: IX_AuditLogs_Action; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IX_AuditLogs_Action" ON public."AuditLogs" USING btree ("Action");


--
-- Name: IX_AuditLogs_CreatedAt; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IX_AuditLogs_CreatedAt" ON public."AuditLogs" USING btree ("CreatedAt");


--
-- Name: IX_AuditLogs_PatientCpf; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IX_AuditLogs_PatientCpf" ON public."AuditLogs" USING btree ("PatientCpf");


--
-- Name: IX_AuditLogs_PatientId; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IX_AuditLogs_PatientId" ON public."AuditLogs" USING btree ("PatientId");


--
-- Name: IX_AuditLogs_UserId; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IX_AuditLogs_UserId" ON public."AuditLogs" USING btree ("UserId");


--
-- Name: IX_CboOccupations_Code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "IX_CboOccupations_Code" ON public."CboOccupations" USING btree ("Code");


--
-- Name: IX_DigitalCertificates_Thumbprint; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IX_DigitalCertificates_Thumbprint" ON public."DigitalCertificates" USING btree ("Thumbprint");


--
-- Name: IX_DigitalCertificates_UserId; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IX_DigitalCertificates_UserId" ON public."DigitalCertificates" USING btree ("UserId");


--
-- Name: IX_ExamRequests_AppointmentId; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IX_ExamRequests_AppointmentId" ON public."ExamRequests" USING btree ("AppointmentId");


--
-- Name: IX_ExamRequests_DocumentHash; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IX_ExamRequests_DocumentHash" ON public."ExamRequests" USING btree ("DocumentHash");


--
-- Name: IX_ExamRequests_PatientId; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IX_ExamRequests_PatientId" ON public."ExamRequests" USING btree ("PatientId");


--
-- Name: IX_ExamRequests_ProfessionalId; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IX_ExamRequests_ProfessionalId" ON public."ExamRequests" USING btree ("ProfessionalId");


--
-- Name: IX_Invites_CreatedBy; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IX_Invites_CreatedBy" ON public."Invites" USING btree ("CreatedBy");


--
-- Name: IX_Invites_Email; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IX_Invites_Email" ON public."Invites" USING btree ("Email");


--
-- Name: IX_Invites_Token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "IX_Invites_Token" ON public."Invites" USING btree ("Token");


--
-- Name: IX_MedicalCertificates_AppointmentId; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IX_MedicalCertificates_AppointmentId" ON public."MedicalCertificates" USING btree ("AppointmentId");


--
-- Name: IX_MedicalCertificates_DocumentHash; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IX_MedicalCertificates_DocumentHash" ON public."MedicalCertificates" USING btree ("DocumentHash");


--
-- Name: IX_MedicalCertificates_PatientId; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IX_MedicalCertificates_PatientId" ON public."MedicalCertificates" USING btree ("PatientId");


--
-- Name: IX_MedicalCertificates_ProfessionalId; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IX_MedicalCertificates_ProfessionalId" ON public."MedicalCertificates" USING btree ("ProfessionalId");


--
-- Name: IX_MedicalReports_AppointmentId; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IX_MedicalReports_AppointmentId" ON public."MedicalReports" USING btree ("AppointmentId");


--
-- Name: IX_MedicalReports_DocumentHash; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IX_MedicalReports_DocumentHash" ON public."MedicalReports" USING btree ("DocumentHash");


--
-- Name: IX_MedicalReports_PatientId; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IX_MedicalReports_PatientId" ON public."MedicalReports" USING btree ("PatientId");


--
-- Name: IX_MedicalReports_ProfessionalId; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IX_MedicalReports_ProfessionalId" ON public."MedicalReports" USING btree ("ProfessionalId");


--
-- Name: IX_Notifications_UserId; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IX_Notifications_UserId" ON public."Notifications" USING btree ("UserId");


--
-- Name: IX_PatientProfiles_Cns; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IX_PatientProfiles_Cns" ON public."PatientProfiles" USING btree ("Cns");


--
-- Name: IX_PatientProfiles_UserId; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "IX_PatientProfiles_UserId" ON public."PatientProfiles" USING btree ("UserId");


--
-- Name: IX_Prescriptions_AppointmentId; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IX_Prescriptions_AppointmentId" ON public."Prescriptions" USING btree ("AppointmentId");


--
-- Name: IX_Prescriptions_DocumentHash; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IX_Prescriptions_DocumentHash" ON public."Prescriptions" USING btree ("DocumentHash");


--
-- Name: IX_Prescriptions_PatientId; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IX_Prescriptions_PatientId" ON public."Prescriptions" USING btree ("PatientId");


--
-- Name: IX_Prescriptions_ProfessionalId; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IX_Prescriptions_ProfessionalId" ON public."Prescriptions" USING btree ("ProfessionalId");


--
-- Name: IX_ProfessionalCouncils_Acronym; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "IX_ProfessionalCouncils_Acronym" ON public."ProfessionalCouncils" USING btree ("Acronym");


--
-- Name: IX_ProfessionalProfiles_CboOccupationId; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IX_ProfessionalProfiles_CboOccupationId" ON public."ProfessionalProfiles" USING btree ("CboOccupationId");


--
-- Name: IX_ProfessionalProfiles_CouncilId; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IX_ProfessionalProfiles_CouncilId" ON public."ProfessionalProfiles" USING btree ("CouncilId");


--
-- Name: IX_ProfessionalProfiles_CouncilRegistration; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IX_ProfessionalProfiles_CouncilRegistration" ON public."ProfessionalProfiles" USING btree ("CouncilRegistration");


--
-- Name: IX_ProfessionalProfiles_Crm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IX_ProfessionalProfiles_Crm" ON public."ProfessionalProfiles" USING btree ("Crm");


--
-- Name: IX_ProfessionalProfiles_SpecialtyId; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IX_ProfessionalProfiles_SpecialtyId" ON public."ProfessionalProfiles" USING btree ("SpecialtyId");


--
-- Name: IX_ProfessionalProfiles_UserId; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "IX_ProfessionalProfiles_UserId" ON public."ProfessionalProfiles" USING btree ("UserId");


--
-- Name: IX_ScheduleBlocks_ApprovedBy; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IX_ScheduleBlocks_ApprovedBy" ON public."ScheduleBlocks" USING btree ("ApprovedBy");


--
-- Name: IX_ScheduleBlocks_ProfessionalId; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IX_ScheduleBlocks_ProfessionalId" ON public."ScheduleBlocks" USING btree ("ProfessionalId");


--
-- Name: IX_Schedules_ProfessionalId; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IX_Schedules_ProfessionalId" ON public."Schedules" USING btree ("ProfessionalId");


--
-- Name: IX_SigtapProcedures_Code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "IX_SigtapProcedures_Code" ON public."SigtapProcedures" USING btree ("Code");


--
-- Name: IX_Users_Cpf; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "IX_Users_Cpf" ON public."Users" USING btree ("Cpf");


--
-- Name: IX_Users_Email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "IX_Users_Email" ON public."Users" USING btree ("Email");


--
-- Name: IX_Users_Phone; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "IX_Users_Phone" ON public."Users" USING btree ("Phone");


--
-- Name: Appointments FK_Appointments_Specialties_SpecialtyId; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Appointments"
    ADD CONSTRAINT "FK_Appointments_Specialties_SpecialtyId" FOREIGN KEY ("SpecialtyId") REFERENCES public."Specialties"("Id") ON DELETE RESTRICT;


--
-- Name: Appointments FK_Appointments_Users_PatientId; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Appointments"
    ADD CONSTRAINT "FK_Appointments_Users_PatientId" FOREIGN KEY ("PatientId") REFERENCES public."Users"("Id") ON DELETE RESTRICT;


--
-- Name: Appointments FK_Appointments_Users_ProfessionalId; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Appointments"
    ADD CONSTRAINT "FK_Appointments_Users_ProfessionalId" FOREIGN KEY ("ProfessionalId") REFERENCES public."Users"("Id") ON DELETE RESTRICT;


--
-- Name: Attachments FK_Attachments_Appointments_AppointmentId; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Attachments"
    ADD CONSTRAINT "FK_Attachments_Appointments_AppointmentId" FOREIGN KEY ("AppointmentId") REFERENCES public."Appointments"("Id") ON DELETE CASCADE;


--
-- Name: AuditLogs FK_AuditLogs_Users_PatientId; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."AuditLogs"
    ADD CONSTRAINT "FK_AuditLogs_Users_PatientId" FOREIGN KEY ("PatientId") REFERENCES public."Users"("Id") ON DELETE SET NULL;


--
-- Name: AuditLogs FK_AuditLogs_Users_UserId; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."AuditLogs"
    ADD CONSTRAINT "FK_AuditLogs_Users_UserId" FOREIGN KEY ("UserId") REFERENCES public."Users"("Id") ON DELETE SET NULL;


--
-- Name: DigitalCertificates FK_DigitalCertificates_Users_UserId; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."DigitalCertificates"
    ADD CONSTRAINT "FK_DigitalCertificates_Users_UserId" FOREIGN KEY ("UserId") REFERENCES public."Users"("Id") ON DELETE CASCADE;


--
-- Name: ExamRequests FK_ExamRequests_Appointments_AppointmentId; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."ExamRequests"
    ADD CONSTRAINT "FK_ExamRequests_Appointments_AppointmentId" FOREIGN KEY ("AppointmentId") REFERENCES public."Appointments"("Id") ON DELETE CASCADE;


--
-- Name: ExamRequests FK_ExamRequests_Users_PatientId; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."ExamRequests"
    ADD CONSTRAINT "FK_ExamRequests_Users_PatientId" FOREIGN KEY ("PatientId") REFERENCES public."Users"("Id") ON DELETE RESTRICT;


--
-- Name: ExamRequests FK_ExamRequests_Users_ProfessionalId; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."ExamRequests"
    ADD CONSTRAINT "FK_ExamRequests_Users_ProfessionalId" FOREIGN KEY ("ProfessionalId") REFERENCES public."Users"("Id") ON DELETE RESTRICT;


--
-- Name: Invites FK_Invites_Users_CreatedBy; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Invites"
    ADD CONSTRAINT "FK_Invites_Users_CreatedBy" FOREIGN KEY ("CreatedBy") REFERENCES public."Users"("Id") ON DELETE RESTRICT;


--
-- Name: MedicalCertificates FK_MedicalCertificates_Appointments_AppointmentId; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."MedicalCertificates"
    ADD CONSTRAINT "FK_MedicalCertificates_Appointments_AppointmentId" FOREIGN KEY ("AppointmentId") REFERENCES public."Appointments"("Id") ON DELETE CASCADE;


--
-- Name: MedicalCertificates FK_MedicalCertificates_Users_PatientId; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."MedicalCertificates"
    ADD CONSTRAINT "FK_MedicalCertificates_Users_PatientId" FOREIGN KEY ("PatientId") REFERENCES public."Users"("Id") ON DELETE RESTRICT;


--
-- Name: MedicalCertificates FK_MedicalCertificates_Users_ProfessionalId; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."MedicalCertificates"
    ADD CONSTRAINT "FK_MedicalCertificates_Users_ProfessionalId" FOREIGN KEY ("ProfessionalId") REFERENCES public."Users"("Id") ON DELETE RESTRICT;


--
-- Name: MedicalReports FK_MedicalReports_Appointments_AppointmentId; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."MedicalReports"
    ADD CONSTRAINT "FK_MedicalReports_Appointments_AppointmentId" FOREIGN KEY ("AppointmentId") REFERENCES public."Appointments"("Id") ON DELETE CASCADE;


--
-- Name: MedicalReports FK_MedicalReports_Users_PatientId; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."MedicalReports"
    ADD CONSTRAINT "FK_MedicalReports_Users_PatientId" FOREIGN KEY ("PatientId") REFERENCES public."Users"("Id") ON DELETE RESTRICT;


--
-- Name: MedicalReports FK_MedicalReports_Users_ProfessionalId; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."MedicalReports"
    ADD CONSTRAINT "FK_MedicalReports_Users_ProfessionalId" FOREIGN KEY ("ProfessionalId") REFERENCES public."Users"("Id") ON DELETE RESTRICT;


--
-- Name: Notifications FK_Notifications_Users_UserId; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Notifications"
    ADD CONSTRAINT "FK_Notifications_Users_UserId" FOREIGN KEY ("UserId") REFERENCES public."Users"("Id") ON DELETE CASCADE;


--
-- Name: PatientProfiles FK_PatientProfiles_Users_UserId; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."PatientProfiles"
    ADD CONSTRAINT "FK_PatientProfiles_Users_UserId" FOREIGN KEY ("UserId") REFERENCES public."Users"("Id") ON DELETE CASCADE;


--
-- Name: Prescriptions FK_Prescriptions_Appointments_AppointmentId; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Prescriptions"
    ADD CONSTRAINT "FK_Prescriptions_Appointments_AppointmentId" FOREIGN KEY ("AppointmentId") REFERENCES public."Appointments"("Id") ON DELETE CASCADE;


--
-- Name: Prescriptions FK_Prescriptions_Users_PatientId; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Prescriptions"
    ADD CONSTRAINT "FK_Prescriptions_Users_PatientId" FOREIGN KEY ("PatientId") REFERENCES public."Users"("Id") ON DELETE RESTRICT;


--
-- Name: Prescriptions FK_Prescriptions_Users_ProfessionalId; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Prescriptions"
    ADD CONSTRAINT "FK_Prescriptions_Users_ProfessionalId" FOREIGN KEY ("ProfessionalId") REFERENCES public."Users"("Id") ON DELETE RESTRICT;


--
-- Name: ProfessionalProfiles FK_ProfessionalProfiles_CboOccupations_CboOccupationId; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."ProfessionalProfiles"
    ADD CONSTRAINT "FK_ProfessionalProfiles_CboOccupations_CboOccupationId" FOREIGN KEY ("CboOccupationId") REFERENCES public."CboOccupations"("Id") ON DELETE SET NULL;


--
-- Name: ProfessionalProfiles FK_ProfessionalProfiles_ProfessionalCouncils_CouncilId; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."ProfessionalProfiles"
    ADD CONSTRAINT "FK_ProfessionalProfiles_ProfessionalCouncils_CouncilId" FOREIGN KEY ("CouncilId") REFERENCES public."ProfessionalCouncils"("Id") ON DELETE SET NULL;


--
-- Name: ProfessionalProfiles FK_ProfessionalProfiles_Specialties_SpecialtyId; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."ProfessionalProfiles"
    ADD CONSTRAINT "FK_ProfessionalProfiles_Specialties_SpecialtyId" FOREIGN KEY ("SpecialtyId") REFERENCES public."Specialties"("Id") ON DELETE SET NULL;


--
-- Name: ProfessionalProfiles FK_ProfessionalProfiles_Users_UserId; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."ProfessionalProfiles"
    ADD CONSTRAINT "FK_ProfessionalProfiles_Users_UserId" FOREIGN KEY ("UserId") REFERENCES public."Users"("Id") ON DELETE CASCADE;


--
-- Name: ScheduleBlocks FK_ScheduleBlocks_Users_ApprovedBy; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."ScheduleBlocks"
    ADD CONSTRAINT "FK_ScheduleBlocks_Users_ApprovedBy" FOREIGN KEY ("ApprovedBy") REFERENCES public."Users"("Id") ON DELETE SET NULL;


--
-- Name: ScheduleBlocks FK_ScheduleBlocks_Users_ProfessionalId; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."ScheduleBlocks"
    ADD CONSTRAINT "FK_ScheduleBlocks_Users_ProfessionalId" FOREIGN KEY ("ProfessionalId") REFERENCES public."Users"("Id") ON DELETE CASCADE;


--
-- Name: Schedules FK_Schedules_Users_ProfessionalId; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Schedules"
    ADD CONSTRAINT "FK_Schedules_Users_ProfessionalId" FOREIGN KEY ("ProfessionalId") REFERENCES public."Users"("Id") ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict Lb5oeHjrGor3NPItVLgSjDPQeghUJtG7WFde2tf7O780U2EL2eC8MihePQukwqW

