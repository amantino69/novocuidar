--
-- PostgreSQL database dump
--

\restrict duTE1PPr5bDNhk5EyG8Lwv5AeVskfLIObL6MWUBhvi0M7jEQVhD1tFvf7GCJvfn

-- Dumped from database version 16.11
-- Dumped by pg_dump version 16.11

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
    "NotificationsSentCount" integer DEFAULT 0 NOT NULL,
    "LastNotificationSentAt" text
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
-- Name: WaitingLists; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."WaitingLists" (
    "Id" text NOT NULL,
    "AppointmentId" text NOT NULL,
    "PatientId" text NOT NULL,
    "ProfessionalId" text NOT NULL,
    "UnityId" text,
    "Position" integer NOT NULL,
    "Priority" integer DEFAULT 0 NOT NULL,
    "CheckInTime" text,
    "CalledTime" text,
    "CallAttempts" integer DEFAULT 0 NOT NULL,
    "Status" integer DEFAULT 0 NOT NULL,
    "CreatedAt" text NOT NULL,
    "UpdatedAt" text NOT NULL,
    "IsSpontaneousDemand" integer DEFAULT 0 NOT NULL,
    "UrgencyLevel" integer DEFAULT 0,
    "ChiefComplaint" text
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

COPY public."Appointments" ("Id", "PatientId", "ProfessionalId", "SpecialtyId", "Date", "Time", "EndTime", "Type", "Status", "Observation", "MeetLink", "PreConsultationJson", "BiometricsJson", "AttachmentsChatJson", "AnamnesisJson", "SoapJson", "SpecialtyFieldsJson", "AISummary", "AISummaryGeneratedAt", "AIDiagnosticHypothesis", "AIDiagnosisGeneratedAt", "CreatedAt", "UpdatedAt", "AssistantId", "CheckInTime", "ConsultationStartedAt", "DoctorJoinedAt", "ConsultationEndedAt", "DurationInMinutes", "NotificationsSentCount", "LastNotificationSentAt") FROM stdin;
5ddeef0f-1ec9-473f-aaa2-b38dd51422d5	6bf6f665-96ba-4aae-8a65-cfba0624bd49	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	48e0503f-d0a3-4702-b050-66d4c20b6d6d	2026-02-04T03:00:00.0000000Z	08:00:00	\N	4	3	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-02-04T06:15:41.0509750Z	2026-02-04T06:30:27.1480310Z	\N	\N	\N	\N	\N	\N	0	\N
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
ff3448fb-a5d8-477a-856e-63f17ba28d4a	\N	login	User	319c95f7-44b6-4536-a2db-64090440b824	\N	{"Email":"adm@adm.com","LoginTime":"2026-02-01T18:46:13.2925411Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-01T18:46:13.3023495Z	2026-02-01T18:46:13.3023497Z	\N	\N	\N	\N
e2861f19-29bb-451e-a834-9372809e44d1	\N	delete	User	bd8a801d-91d4-4147-91d5-5dfcd1bef475	{"Email":"medico.iomt@teste.com","Name":"Dr. IoMT","LastName":"Teste","Role":"PROFESSIONAL"}	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-01T18:57:27.5568224Z	2026-02-01T18:57:27.5568224Z	\N	\N	\N	\N
9f0f773c-e19f-4e2e-9e51-09bbcc05a5dd	\N	delete	User	3354709f-6c55-4230-be80-1b64d565aa71	{"Email":"daniel@telecuidar.com","Name":"daniel","LastName":"carrara","Role":"PATIENT"}	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-01T18:57:31.9402101Z	2026-02-01T18:57:31.9402106Z	\N	\N	\N	\N
f64a5a10-ca11-4311-81d3-be82a283c561	\N	delete	User	c5506679-4d7f-43fe-aa65-aa4078c0f907	{"Email":"paciente.iomt@teste.com","Name":"Paciente IoMT","LastName":"Teste","Role":"PATIENT"}	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-01T18:57:37.4203090Z	2026-02-01T18:57:37.4203091Z	\N	\N	\N	\N
96e64f1b-77e3-4b4d-af9d-12c3fc6777a4	\N	create	Schedule	a7590ad6-c3f5-4fc2-9390-a98f7e9d79c4	\N	{"ProfessionalId":"aaaa5050-dfc2-42d9-a849-ab9a8b354cac","ValidityStartDate":"2026-02-01","Status":"Active"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-01T19:01:17.2733665Z	2026-02-01T19:01:17.2733666Z	\N	\N	\N	\N
c21a8066-3887-4b30-95c6-b6f0c9465178	\N	update	Schedule	a7590ad6-c3f5-4fc2-9390-a98f7e9d79c4	{"ValidityStartDate":"2026-02-01","Status":"Active"}	{"ValidityStartDate":"2026-02-01","Status":"Active"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-01T19:04:19.7970973Z	2026-02-01T19:04:19.7970973Z	\N	\N	\N	\N
d5230ca9-71ba-489a-a9da-969e05d64f6c	8bbb6c58-b963-4f67-b001-c8fa41582afd	delete	User	319c95f7-44b6-4536-a2db-64090440b824	{"Email":"adm@adm.com","Name":"Admin","LastName":"Teste","Role":"ADMIN"}	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 Edg/144.0.0.0	2026-02-03T02:29:27.1428564Z	2026-02-03T02:29:27.1428565Z	\N	\N	\N	\N
7606b35b-26f5-4fb0-be73-057cf5d952f5	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	91bce788-2b3b-4a2b-bb83-62eabc7b2727	\N	{"RoomName":"91bce7882b3b4a2bbb8362eabc7b2727","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T10:54:37.2401335Z	2026-02-03T10:54:37.2401335Z	\N	\N	\N	\N
f515a02b-44e7-4543-935b-206e2a4009f0	d61f6fb1-d2cd-4350-b242-003ac3a4464f	login	User	d61f6fb1-d2cd-4350-b242-003ac3a4464f	\N	{"Email":"enf_do@telecuidar.com","LoginTime":"2026-02-03T12:12:22.9259583Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T12:12:22.9260676Z	2026-02-03T12:12:22.9260677Z	\N	\N	\N	\N
8077a6db-854f-4fe6-a27a-4c069ff22348	\N	login	User	49f0cc4c-0116-45bc-a5cb-4991a0f4b872	\N	{"Email":"paciente@paciente.com","LoginTime":"2026-02-01T18:59:41.8952929Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-01T18:59:41.8953818Z	2026-02-01T18:59:41.8953819Z	\N	\N	\N	\N
6ebf78e9-b734-4c8d-948b-88e54210319f	\N	create	Appointment	9fe4d47d-bb0d-4db0-9bc7-a726f6029278	\N	{"PatientId":"49f0cc4c-0116-45bc-a5cb-4991a0f4b872","ProfessionalId":"aaaa5050-dfc2-42d9-a849-ab9a8b354cac","Date":"2026-02-02T03:00:00Z","Time":"08:00","Status":"Scheduled"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-01T19:05:16.4133469Z	2026-02-01T19:05:16.4133472Z	\N	\N	\N	\N
e4b3a19f-187f-4169-9a23-e3b24f6399fe	\N	login	User	3210fa34-8242-4916-a864-7f8fa0eb2265	\N	{"Email":"pac@pac.com","LoginTime":"2026-02-01T18:47:58.4830791Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-01T18:47:58.4831897Z	2026-02-01T18:47:58.4831897Z	\N	\N	\N	\N
202a6860-f985-49ed-8c46-fe0c17ae10ec	\N	login	User	aaaa5050-dfc2-42d9-a849-ab9a8b354cac	\N	{"Email":"med@med.com","LoginTime":"2026-02-01T18:47:28.9801566Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-01T18:47:28.9802577Z	2026-02-01T18:47:28.9802579Z	\N	\N	\N	\N
f003fde7-76a2-4658-a30d-a7dc3c4570d4	\N	login	User	319c95f7-44b6-4536-a2db-64090440b824	\N	{"Email":"adm@adm.com","LoginTime":"2026-02-01T20:23:14.9284397Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-01T20:23:14.9285178Z	2026-02-01T20:23:14.9285179Z	\N	\N	\N	\N
59da92a0-cb2e-4135-b080-ced1f9676193	\N	login	User	319c95f7-44b6-4536-a2db-64090440b824	\N	{"Email":"adm@adm.com","LoginTime":"2026-02-01T21:59:11.7426713Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-01T21:59:11.7638986Z	2026-02-01T21:59:11.7638989Z	\N	\N	\N	\N
8e07f68c-f7a2-49ff-a76f-2243e19d7764	\N	login	User	319c95f7-44b6-4536-a2db-64090440b824	\N	{"Email":"adm@adm.com","LoginTime":"2026-02-01T22:08:14.4069904Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 Edg/144.0.0.0	2026-02-01T22:08:14.4071902Z	2026-02-01T22:08:14.4071904Z	\N	\N	\N	\N
f925d280-9776-413b-b39a-9eaf6df8dfc0	\N	login	User	319c95f7-44b6-4536-a2db-64090440b824	\N	{"Email":"adm@adm.com","LoginTime":"2026-02-01T22:08:54.0131379Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 Edg/144.0.0.0	2026-02-01T22:08:54.0132492Z	2026-02-01T22:08:54.0132493Z	\N	\N	\N	\N
0e9ff989-1fde-4c0e-8e90-01893497651b	\N	create	User	4292737d-cd27-449d-8350-71afa93f8fde	\N	{"Email":"amantino@yahoo.com","Name":"Cl\\u00E1udio","LastName":"Amantino","Role":0}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-01T22:15:56.0259829Z	2026-02-01T22:15:56.0259832Z	\N	\N	\N	\N
5e550b3b-28d1-4aee-9604-619e2746f0f2	8bbb6c58-b963-4f67-b001-c8fa41582afd	delete	User	4292737d-cd27-449d-8350-71afa93f8fde	{"Email":"amantino@yahoo.com","Name":"Cl\\u00E1udio","LastName":"Amantino","Role":"PATIENT"}	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 Edg/144.0.0.0	2026-02-03T02:29:34.3632421Z	2026-02-03T02:29:34.3632423Z	\N	\N	\N	\N
8d51361e-cc93-40dc-91e5-944ed3abfd90	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	91bce788-2b3b-4a2b-bb83-62eabc7b2727	\N	{"RoomName":"91bce7882b3b4a2bbb8362eabc7b2727","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T10:55:02.1426836Z	2026-02-03T10:55:02.1426838Z	\N	\N	\N	\N
d2299602-dc28-4ebb-85b8-685b79e07af7	f00d2c7c-cca1-4758-b64a-740042d900c5	login	User	f00d2c7c-cca1-4758-b64a-740042d900c5	\N	{"Email":"rec_ma@telecuidar.com","LoginTime":"2026-02-03T12:30:42.6964452Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T12:30:42.6965335Z	2026-02-03T12:30:42.6965336Z	\N	\N	\N	\N
ca36da73-3a2e-4257-b600-c20e2f2701bd	\N	login	User	2b5977b6-913a-4ae4-badd-9aa89f654806	\N	{"Email":"enf_do@telecuidar.com","LoginTime":"2026-02-01T22:27:57.6094017Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-01T22:27:57.6260483Z	2026-02-01T22:27:57.6260485Z	\N	\N	\N	\N
17a0f942-e569-42e0-b047-eb57088b82ea	\N	login	User	cf633cef-6fe9-4164-836e-dad4a67cecc6	\N	{"Email":"adm_ca@telecuidar.com","LoginTime":"2026-02-01T22:30:50.655368Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 Edg/144.0.0.0	2026-02-01T22:30:50.6554879Z	2026-02-01T22:30:50.6554880Z	\N	\N	\N	\N
8547eade-3c7f-4627-bc1a-14bef415ffa0	\N	login	User	94209b8d-fb6d-46f0-b604-2b52736c8737	\N	{"Email":"enf_do@telecuidar.com","LoginTime":"2026-02-02T11:18:41.3361215Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T11:18:41.3371696Z	2026-02-02T11:18:41.3371698Z	\N	\N	\N	\N
4c46b12a-d343-4d92-b132-b8e42c2ba8d0	\N	login	User	9406a1f0-1f86-48af-8259-234bf7e72571	\N	{"Email":"assist@assist.com","LoginTime":"2026-02-01T20:20:35.7386655Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-01T20:20:35.7387352Z	2026-02-01T20:20:35.7387353Z	\N	\N	\N	\N
75479d83-65f4-4030-bc44-abfdc24a88f9	\N	login	User	aaaa5050-dfc2-42d9-a849-ab9a8b354cac	\N	{"Email":"med@med.com","LoginTime":"2026-02-01T20:21:22.5205247Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-01T20:21:22.5206074Z	2026-02-01T20:21:22.5206075Z	\N	\N	\N	\N
6f464612-edb1-44ab-8d98-4dd1f2cb3f25	\N	jitsi_access	Appointment	9fe4d47d-bb0d-4db0-9bc7-a726f6029278	\N	{"RoomName":"9fe4d47dbb0d4db09bc7a726f6029278","IsModerator":true,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-01T20:21:30.7502475Z	2026-02-01T20:21:30.7502476Z	\N	\N	\N	\N
c8a93ae8-1ec5-4d38-b733-bf5c87d1e3a8	\N	VIEW_CLINICAL_TIMELINE	Patient	49f0cc4c-0116-45bc-a5cb-4991a0f4b872	\N	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-01T20:21:47.6003113Z	2026-02-01T20:21:47.6003116Z	Visualiza├º├úo durante teleconsulta	PRONTUARIO	55060447049	\N
016682f6-56d5-401d-9e9c-a045816f016b	\N	jitsi_access	Appointment	b421227d-4f76-446c-b89f-1fa8dffb0cc0	\N	{"RoomName":"b421227d4f76446cb89f1fa8dffb0cc0","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-01T22:28:04.8158533Z	2026-02-01T22:28:04.8158536Z	\N	\N	\N	\N
5870a2e9-565c-4158-bf77-843aad96b98c	\N	jitsi_access	Appointment	b421227d-4f76-446c-b89f-1fa8dffb0cc0	\N	{"RoomName":"b421227d4f76446cb89f1fa8dffb0cc0","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-01T22:51:04.5264193Z	2026-02-01T22:51:04.5264195Z	\N	\N	\N	\N
9653334c-5274-4bd3-bfb5-2a1cd2286e74	\N	jitsi_access	Appointment	b421227d-4f76-446c-b89f-1fa8dffb0cc0	\N	{"RoomName":"b421227d4f76446cb89f1fa8dffb0cc0","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-01T23:09:58.1722929Z	2026-02-01T23:09:58.1722932Z	\N	\N	\N	\N
8fdbc625-c79f-4abb-a5fb-fc5569aa079f	\N	login	User	cf633cef-6fe9-4164-836e-dad4a67cecc6	\N	{"Email":"adm_ca@telecuidar.com","LoginTime":"2026-02-01T22:32:10.1507319Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 Edg/144.0.0.0	2026-02-01T22:32:10.1508051Z	2026-02-01T22:32:10.1508051Z	\N	\N	\N	\N
a58ddba2-6ccf-4dbb-a176-d67892729f45	\N	create	Specialty	24d7a0ea-adde-436f-97a8-1fffcd87762b	\N	{"Name":"Geriatria","Description":"Sa\\u00FAde da terceira idade","Status":"Active"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 Edg/144.0.0.0	2026-02-01T22:34:12.0782491Z	2026-02-01T22:34:12.0782491Z	\N	\N	\N	\N
5afe8b71-4eb2-42e9-bc07-f019420fc97c	\N	login	User	9d0bd387-348d-423d-90e6-9592dda05f50	\N	{"Email":"pac_dc@telecuidar.com","LoginTime":"2026-02-01T22:32:52.7992268Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 Edg/144.0.0.0	2026-02-01T22:32:52.7993192Z	2026-02-01T22:32:52.7993193Z	\N	\N	\N	\N
2d8e3bef-ab24-4c53-88f7-acab3acffca9	f00d2c7c-cca1-4758-b64a-740042d900c5	spontaneous_demand_created	Appointment	f26a3c01-d033-4f0e-a363-76cc4c14fe50	\N	Demanda espont├ónea criada: Daniel - Psiquiatria (Urg├¬ncia: Red)	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T02:32:02.3145389Z	2026-02-03T02:32:02.3145392Z	\N	\N	\N	\N
5aa477e5-96ff-4618-b45a-297c128f35ca	d61f6fb1-d2cd-4350-b242-003ac3a4464f	start_consultation	Appointment	6018ee39-59ac-44bf-b409-9875b5c17169	{"Status":3}	{"Status":"InProgress","ConsultationStartedAt":"2026-02-03T02:32:32.3551576Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T02:32:32.3918348Z	2026-02-03T02:32:32.3918350Z	\N	\N	\N	\N
14d044e8-93fb-4518-96e4-d1e5b9e20487	f00d2c7c-cca1-4758-b64a-740042d900c5	spontaneous_demand_created	Appointment	d8567e18-665b-4421-9746-27f728456f76	\N	Demanda espont├ónea criada: Daniel - Psiquiatria (Urg├¬ncia: Red)	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T11:31:01.6487648Z	2026-02-03T11:31:01.6487649Z	\N	\N	\N	\N
7b73cefb-da4e-4000-b314-3c3ee9f8e1ab	\N	login	User	3b453c62-860d-4c07-8908-d854fd469184	\N	{"Email":"rec_ma@telecuidar.com","LoginTime":"2026-02-01T23:39:46.4033194Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-01T23:39:46.4279591Z	2026-02-01T23:39:46.4279595Z	\N	\N	\N	\N
1a51b6cc-2ae4-45e5-812c-5b3c451c355d	\N	login	User	3b453c62-860d-4c07-8908-d854fd469184	\N	{"Email":"rec_ma@telecuidar.com","LoginTime":"2026-02-01T23:44:07.3915038Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-01T23:44:07.3922275Z	2026-02-01T23:44:07.3922276Z	\N	\N	\N	\N
80efab61-ba1f-44a5-aee2-ae312df9cdb9	\N	login	User	3b453c62-860d-4c07-8908-d854fd469184	\N	{"Email":"rec_ma@telecuidar.com","LoginTime":"2026-02-01T23:53:54.0398108Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-01T23:53:54.0399376Z	2026-02-01T23:53:54.0399377Z	\N	\N	\N	\N
690d7d2d-7c15-4f79-bf38-c15680bf8ec6	f00d2c7c-cca1-4758-b64a-740042d900c5	spontaneous_demand_created	Appointment	b436b904-02c5-4e0b-840e-04a7fc302994	\N	Demanda espont├ónea criada: Daniel - Psiquiatria (Urg├¬ncia: Red)	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T12:31:01.9371201Z	2026-02-03T12:31:01.9371204Z	\N	\N	\N	\N
81fecabf-1741-44a4-bba8-893420b46c2c	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	91bce788-2b3b-4a2b-bb83-62eabc7b2727	\N	{"RoomName":"91bce7882b3b4a2bbb8362eabc7b2727","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T12:31:36.6948026Z	2026-02-03T12:31:36.6948026Z	\N	\N	\N	\N
bae3b577-1855-42f5-8182-50b16a594659	\N	login	User	03f63cc5-4307-402b-9130-c8c787abb5d0	\N	{"Email":"rec_ma@telecuidar.com","LoginTime":"2026-02-02T00:07:17.6048935Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T00:07:17.6050060Z	2026-02-02T00:07:17.6050060Z	\N	\N	\N	\N
21e49f3e-f646-44ac-9ecb-5b58e062f224	\N	login	User	03f63cc5-4307-402b-9130-c8c787abb5d0	\N	{"Email":"rec_ma@telecuidar.com","LoginTime":"2026-02-02T00:11:20.2961776Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T00:11:20.2963053Z	2026-02-02T00:11:20.2963054Z	\N	\N	\N	\N
dd18c112-3098-4cde-8c15-276b3b997ea4	\N	login	User	df79b61e-84a1-4e60-9438-02f79b73c549	\N	{"Email":"rec_ma@telecuidar.com","LoginTime":"2026-02-02T00:25:19.2396247Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T00:25:19.2397288Z	2026-02-02T00:25:19.2397289Z	\N	\N	\N	\N
ba4ee00a-f730-423b-9a07-47f876177760	\N	login	User	df79b61e-84a1-4e60-9438-02f79b73c549	\N	{"Email":"rec_ma@telecuidar.com","LoginTime":"2026-02-02T00:32:07.5074909Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T00:32:07.5075901Z	2026-02-02T00:32:07.5075902Z	\N	\N	\N	\N
eead735c-366e-44aa-93db-8e64a4de17b7	\N	login	User	df79b61e-84a1-4e60-9438-02f79b73c549	\N	{"Email":"rec_ma@telecuidar.com","LoginTime":"2026-02-02T00:34:17.2767194Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T00:34:17.2768343Z	2026-02-02T00:34:17.2768344Z	\N	\N	\N	\N
578d6826-7e0a-4645-bca9-30ef3f2c725b	\N	login	User	df79b61e-84a1-4e60-9438-02f79b73c549	\N	{"Email":"rec_ma@telecuidar.com","LoginTime":"2026-02-02T00:38:41.3181796Z"}	127.0.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; pt-BR) WindowsPowerShell/5.1.26100.7462	2026-02-02T00:38:41.3198749Z	2026-02-02T00:38:41.3198750Z	\N	\N	\N	\N
29965dc6-e7b3-40da-b52c-c09cad665ff7	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	6018ee39-59ac-44bf-b409-9875b5c17169	\N	{"RoomName":"6018ee3959ac44bfb4099875b5c17169","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T02:32:32.8345158Z	2026-02-03T02:32:32.8345161Z	\N	\N	\N	\N
a72f14bf-31fe-4b1f-a918-b271064a0120	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	login	User	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	\N	{"Email":"med_aj@telecuidar.com","LoginTime":"2026-02-03T02:34:49.0272276Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 Edg/144.0.0.0	2026-02-03T02:34:49.0273054Z	2026-02-03T02:34:49.0273054Z	\N	\N	\N	\N
35053593-dd0b-429e-8eb3-98bbf6241e64	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	91bce788-2b3b-4a2b-bb83-62eabc7b2727	\N	{"RoomName":"91bce7882b3b4a2bbb8362eabc7b2727","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T11:40:40.6237199Z	2026-02-03T11:40:40.6237200Z	\N	\N	\N	\N
f3a747c3-9332-45d9-bba4-a6803792c644	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	91bce788-2b3b-4a2b-bb83-62eabc7b2727	\N	{"RoomName":"91bce7882b3b4a2bbb8362eabc7b2727","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T13:00:01.8287006Z	2026-02-03T13:00:01.8287007Z	\N	\N	\N	\N
9a960164-a12d-45e8-b5b8-8f146f4b4437	d61f6fb1-d2cd-4350-b242-003ac3a4464f	login	User	d61f6fb1-d2cd-4350-b242-003ac3a4464f	\N	{"Email":"enf_do@telecuidar.com","LoginTime":"2026-02-03T13:34:46.7344302Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T13:34:46.7353989Z	2026-02-03T13:34:46.7353992Z	\N	\N	\N	\N
b180bc57-6859-489a-95d5-b21065410362	\N	login	User	135faffd-2126-442a-be4a-98365e637a3e	\N	{"Email":"enf_do@telecuidar.com","LoginTime":"2026-02-02T00:47:41.2958438Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T00:47:41.2959334Z	2026-02-02T00:47:41.2959334Z	\N	\N	\N	\N
d98ff9d5-ad6a-4158-bb58-1a0e5275c8ca	\N	login	User	df79b61e-84a1-4e60-9438-02f79b73c549	\N	{"Email":"rec_ma@telecuidar.com","LoginTime":"2026-02-02T00:41:14.5052473Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T00:41:14.5053512Z	2026-02-02T00:41:14.5053513Z	\N	\N	\N	\N
abd4255c-77e0-48ec-a4c9-f8f1041878c2	\N	login	User	df79b61e-84a1-4e60-9438-02f79b73c549	\N	{"Email":"rec_ma@telecuidar.com","LoginTime":"2026-02-02T00:44:49.8829421Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T00:44:49.8830362Z	2026-02-02T00:44:49.8830363Z	\N	\N	\N	\N
603e1f58-2d45-4af4-b268-8a5fe7898391	\N	login	User	df79b61e-84a1-4e60-9438-02f79b73c549	\N	{"Email":"rec_ma@telecuidar.com","LoginTime":"2026-02-02T00:48:04.9219677Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T00:48:04.9220425Z	2026-02-02T00:48:04.9220425Z	\N	\N	\N	\N
de28bec0-85f7-4310-8bb5-7338da7eac8d	\N	login	User	df79b61e-84a1-4e60-9438-02f79b73c549	\N	{"Email":"rec_ma@telecuidar.com","LoginTime":"2026-02-02T00:52:35.3511786Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T00:52:35.3512583Z	2026-02-02T00:52:35.3512584Z	\N	\N	\N	\N
cfc65ece-46bb-4ecf-ae55-a840b3cf514c	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	d8567e18-665b-4421-9746-27f728456f76	\N	{"RoomName":"d8567e18665b4421974627f728456f76","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T13:52:22.5018962Z	2026-02-03T13:52:22.5018963Z	\N	\N	\N	\N
ea709f49-45eb-497e-b915-4bbbb9933b7d	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	d8567e18-665b-4421-9746-27f728456f76	\N	{"RoomName":"d8567e18665b4421974627f728456f76","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T14:12:42.5567016Z	2026-02-03T14:12:42.5567017Z	\N	\N	\N	\N
c2ef891d-36b6-4a6a-a0e9-44f8b1158a91	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	jitsi_access	Appointment	91bce788-2b3b-4a2b-bb83-62eabc7b2727	\N	{"RoomName":"91bce7882b3b4a2bbb8362eabc7b2727","IsModerator":true,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T14:31:20.7882319Z	2026-02-03T14:31:20.7882320Z	\N	\N	\N	\N
1225d8e6-6c90-4e60-96bc-cc3c2c516bfa	\N	login	User	3eadaa37-2e16-4270-9954-c3e8bd0c5bf0	\N	{"Email":"rec_ma@telecuidar.com","LoginTime":"2026-02-02T00:56:25.9475232Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T00:56:25.9690777Z	2026-02-02T00:56:25.9690782Z	\N	\N	\N	\N
dc748df7-d679-44b4-9d31-243d7cef2515	\N	login	User	3eadaa37-2e16-4270-9954-c3e8bd0c5bf0	\N	{"Email":"rec_ma@telecuidar.com","LoginTime":"2026-02-02T01:02:58.6132399Z"}	127.0.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; pt-BR) WindowsPowerShell/5.1.26100.7462	2026-02-02T01:02:58.6141090Z	2026-02-02T01:02:58.6141092Z	\N	\N	\N	\N
c8a3f9f2-5acb-4b23-931f-a23124480a86	\N	login	User	3eadaa37-2e16-4270-9954-c3e8bd0c5bf0	\N	{"Email":"rec_ma@telecuidar.com","LoginTime":"2026-02-02T01:03:09.2622903Z"}	127.0.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; pt-BR) WindowsPowerShell/5.1.26100.7462	2026-02-02T01:03:09.2623920Z	2026-02-02T01:03:09.2623920Z	\N	\N	\N	\N
2a169aa5-7412-4650-85f0-02aee098cd74	\N	login	User	3eadaa37-2e16-4270-9954-c3e8bd0c5bf0	\N	{"Email":"rec_ma@telecuidar.com","LoginTime":"2026-02-02T01:12:24.9015148Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T01:12:24.9016361Z	2026-02-02T01:12:24.9016362Z	\N	\N	\N	\N
8d185278-4dd9-415c-a2ef-de084734aa9d	\N	login	User	3eadaa37-2e16-4270-9954-c3e8bd0c5bf0	\N	{"Email":"rec_ma@telecuidar.com","LoginTime":"2026-02-02T01:17:55.6521873Z"}	127.0.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; pt-BR) WindowsPowerShell/5.1.26100.7462	2026-02-02T01:17:55.6523746Z	2026-02-02T01:17:55.6523747Z	\N	\N	\N	\N
93245a55-6686-4f02-aed6-82c0cf8a7378	\N	login	User	3eadaa37-2e16-4270-9954-c3e8bd0c5bf0	\N	{"Email":"rec_ma@telecuidar.com","LoginTime":"2026-02-02T01:23:45.5397521Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Code/1.108.2 Chrome/142.0.7444.235 Electron/39.2.7 Safari/537.36	2026-02-02T01:23:45.5401240Z	2026-02-02T01:23:45.5401242Z	\N	\N	\N	\N
628dd834-35a6-4f89-bc2f-79721529e6cc	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	login	User	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	\N	{"Email":"med_aj@telecuidar.com","LoginTime":"2026-02-03T02:37:12.8208536Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 Edg/144.0.0.0	2026-02-03T02:37:12.8209333Z	2026-02-03T02:37:12.8209335Z	\N	\N	\N	\N
4b906e3e-a210-46ac-ba06-1756c1140d5d	\N	login	User	3eadaa37-2e16-4270-9954-c3e8bd0c5bf0	\N	{"Email":"rec_ma@telecuidar.com","LoginTime":"2026-02-02T02:05:32.2560714Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T02:05:32.2561473Z	2026-02-02T02:05:32.2561474Z	\N	\N	\N	\N
06e3b94a-6231-4d29-a6b5-001c2e6cccc0	\N	login	User	351e90f9-a294-4c5b-8320-ee5145a243fc	\N	{"Email":"pac_dc@telecuidar.com","LoginTime":"2026-02-02T02:03:20.0493501Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T02:03:20.0503508Z	2026-02-02T02:03:20.0503510Z	\N	\N	\N	\N
6e4d2cb2-74e6-4cc3-9ce2-2c5205823690	\N	create	Appointment	ae91f852-63b0-479d-b5d2-f569904c5dba	\N	{"PatientId":"351e90f9-a294-4c5b-8320-ee5145a243fc","ProfessionalId":"0f42574d-5b3d-455a-9778-eac6cb226a37","Date":"2026-02-02T03:00:00Z","Time":"08:00","Status":"Scheduled"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T02:04:28.6701856Z	2026-02-02T02:04:28.6701857Z	\N	\N	\N	\N
47791eec-c292-4715-ae21-4d48cd10aa57	\N	jitsi_access	Appointment	ae91f852-63b0-479d-b5d2-f569904c5dba	\N	{"RoomName":"ae91f85263b0479db5d2f569904c5dba","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T02:04:42.4096570Z	2026-02-02T02:04:42.4096576Z	\N	\N	\N	\N
00b75e3d-c890-4e24-b306-7adde05ec22a	d61f6fb1-d2cd-4350-b242-003ac3a4464f	login	User	d61f6fb1-d2cd-4350-b242-003ac3a4464f	\N	{"Email":"enf_do@telecuidar.com","LoginTime":"2026-02-03T11:48:38.695793Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T11:48:38.6990964Z	2026-02-03T11:48:38.6990966Z	\N	\N	\N	\N
22ddafb7-f777-41db-bbef-8da61531564e	\N	login	User	60086e82-3497-4fe7-a9a7-a856ba173d05	\N	{"Email":"rec_ma@telecuidar.com","LoginTime":"2026-02-02T03:13:18.6066458Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T03:13:18.6278404Z	2026-02-02T03:13:18.6278406Z	\N	\N	\N	\N
b756c469-1779-4bbd-aa70-4de87c677cdb	\N	login	User	720394a2-bd2e-40db-8266-8e17e978e997	\N	{"Email":"adm_ca@telecuidar.com","LoginTime":"2026-02-02T03:29:56.6847696Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T03:29:56.6855052Z	2026-02-02T03:29:56.6855053Z	\N	\N	\N	\N
350a693f-03ae-4cb2-973a-f10bc6e8eae8	\N	login	User	4df6cc33-bb8e-4e50-a756-e1d1fd76bcf7	\N	{"Email":"enf_do@telecuidar.com","LoginTime":"2026-02-02T03:50:25.6489501Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T03:50:25.6498226Z	2026-02-02T03:50:25.6498228Z	\N	\N	\N	\N
57b9720c-b020-414d-80cf-5ab20378b1dc	\N	jitsi_access	Appointment	59f4f4b8-dfe1-4a2e-ad7f-8129df00127e	\N	{"RoomName":"59f4f4b8dfe14a2ead7f8129df00127e","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T03:51:05.8434995Z	2026-02-02T03:51:05.8434996Z	\N	\N	\N	\N
d33cd8a5-a596-425c-8a54-cbef20d03161	\N	login	User	d7476599-cfda-4afa-aa03-aabee3a9e21d	\N	{"Email":"rec_ma@telecuidar.com","LoginTime":"2026-02-02T03:48:09.1025514Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T03:48:09.1135937Z	2026-02-02T03:48:09.1135939Z	\N	\N	\N	\N
31439b61-00b8-4c0e-b0b3-648e16882e13	\N	login	User	d7476599-cfda-4afa-aa03-aabee3a9e21d	\N	{"Email":"rec_ma@telecuidar.com","LoginTime":"2026-02-02T03:52:59.5673919Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T03:52:59.5674969Z	2026-02-02T03:52:59.5674970Z	\N	\N	\N	\N
281e58c1-053b-45c1-aa2e-5019ad9f2f06	\N	login	User	d7476599-cfda-4afa-aa03-aabee3a9e21d	\N	{"Email":"rec_ma@telecuidar.com","LoginTime":"2026-02-02T03:57:34.0962703Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T03:57:34.0963413Z	2026-02-02T03:57:34.0963414Z	\N	\N	\N	\N
e02b5af7-5e0a-421f-a41f-601b6fd24978	\N	login	User	36782ea4-0cb3-48b6-8c76-1adcd9ecd34f	\N	{"Email":"rec_ma@telecuidar.com","LoginTime":"2026-02-02T04:14:24.2586152Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T04:14:24.2668749Z	2026-02-02T04:14:24.2668750Z	\N	\N	\N	\N
44eb0ffd-9ab6-4160-b25d-f793a89fab7b	\N	login	User	87bf78b7-1261-42c4-8038-846a420c36ce	\N	{"Email":"enf_do@telecuidar.com","LoginTime":"2026-02-02T04:16:33.7844012Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T04:16:33.7850794Z	2026-02-02T04:16:33.7850795Z	\N	\N	\N	\N
f8fd18e0-0cae-4b24-9294-4275edbc9d9a	\N	jitsi_access	Appointment	dda8e4f8-2c6e-43bb-a08b-e90078b7122b	\N	{"RoomName":"dda8e4f82c6e43bba08be90078b7122b","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T04:18:39.4280982Z	2026-02-02T04:18:39.4280983Z	\N	\N	\N	\N
9ab734c2-7777-4f74-8390-88dafa28f168	\N	login	User	52c53bdc-42b0-4617-9ff5-53e19a7d87fc	\N	{"Email":"rec_ma@telecuidar.com","LoginTime":"2026-02-02T10:43:52.2760155Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T10:43:52.2767250Z	2026-02-02T10:43:52.2767251Z	\N	\N	\N	\N
463c9c76-190f-4f8b-b453-f9d5b01ba935	\N	login	User	988f47bf-7491-40bc-9033-ee969000dca8	\N	{"Email":"adm_ca@telecuidar.com","LoginTime":"2026-02-02T11:00:33.8520102Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 Edg/144.0.0.0	2026-02-02T11:00:33.8521001Z	2026-02-02T11:00:33.8521002Z	\N	\N	\N	\N
9a1d2f0d-3e63-4167-bfcf-999dce292234	\N	login	User	ba9b76ee-ca56-4109-a93e-42e183fcab3e	\N	{"Email":"enf_do@telecuidar.com","LoginTime":"2026-02-02T10:42:36.2739961Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T10:42:36.3050684Z	2026-02-02T10:42:36.3050687Z	\N	\N	\N	\N
26684edc-db16-4ec0-8b07-f71cca8fed9d	\N	login	User	767c5a3b-febe-4268-8e72-287a161a9dd8	\N	{"Email":"rec_ma@telecuidar.com","LoginTime":"2026-02-02T11:17:54.6002919Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T11:17:54.6138577Z	2026-02-02T11:17:54.6138580Z	\N	\N	\N	\N
6d7ae8aa-7715-4f5f-a85d-6a43ebe5ca0a	f00d2c7c-cca1-4758-b64a-740042d900c5	spontaneous_demand_created	Appointment	965b952f-ca63-47e8-ad77-a92a2012c709	\N	Demanda espont├ónea criada: Daniel - Psiquiatria (Urg├¬ncia: Red)	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T02:37:47.3148856Z	2026-02-03T02:37:47.3148857Z	\N	\N	\N	\N
1dd6b901-024b-4dbf-b829-23e66a3014b1	\N	login	User	3e98e5e6-c204-496d-baf0-fd7d371ccc16	\N	{"Email":"rec_ma@telecuidar.com","LoginTime":"2026-02-02T12:40:58.5271889Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T12:40:58.5280488Z	2026-02-02T12:40:58.5280489Z	\N	\N	\N	\N
886f1665-57fd-4b33-97a6-1ca7cd38a331	\N	spontaneous_demand_created	Appointment	a125c33f-398e-419a-89cd-5325cffd87e8	\N	Demanda espont├ónea criada: Daniel - Cardiologia (Urg├¬ncia: Red)	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T12:41:32.1374596Z	2026-02-02T12:41:32.1374598Z	\N	\N	\N	\N
8db0141f-76ad-4047-b968-4226e3a8986a	\N	login	User	b10b1f8f-6f7d-4a96-ac6d-bff32ca62ff5	\N	{"Email":"enf_do@telecuidar.com","LoginTime":"2026-02-02T12:36:39.1473368Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T12:36:39.1543722Z	2026-02-02T12:36:39.1543723Z	\N	\N	\N	\N
ce7fb377-ddb1-4922-8b0d-de2c9d0d19d1	d61f6fb1-d2cd-4350-b242-003ac3a4464f	start_consultation	Appointment	d8567e18-665b-4421-9746-27f728456f76	{"Status":3}	{"Status":"InProgress","ConsultationStartedAt":"2026-02-03T11:48:48.5090255Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T11:48:48.5216275Z	2026-02-03T11:48:48.5216276Z	\N	\N	\N	\N
4a3d78e5-6d75-4ec3-8380-919dcbce7829	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	d8567e18-665b-4421-9746-27f728456f76	\N	{"RoomName":"d8567e18665b4421974627f728456f76","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T11:48:48.6453469Z	2026-02-03T11:48:48.6453469Z	\N	\N	\N	\N
1a8d23e9-39f5-47dd-a2c4-e7bf8f5ad83d	d61f6fb1-d2cd-4350-b242-003ac3a4464f	login	User	d61f6fb1-d2cd-4350-b242-003ac3a4464f	\N	{"Email":"enf_do@telecuidar.com","LoginTime":"2026-02-03T13:02:33.1259586Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T13:02:33.1298336Z	2026-02-03T13:02:33.1298337Z	\N	\N	\N	\N
17914428-6236-467a-b16a-2d1f0c2ba16a	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	d8567e18-665b-4421-9746-27f728456f76	\N	{"RoomName":"d8567e18665b4421974627f728456f76","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T13:34:51.6598174Z	2026-02-03T13:34:51.6598174Z	\N	\N	\N	\N
33381ae9-885d-42c3-b9dc-0a2d71e68610	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	d8567e18-665b-4421-9746-27f728456f76	\N	{"RoomName":"d8567e18665b4421974627f728456f76","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T13:55:28.8142246Z	2026-02-03T13:55:28.8142247Z	\N	\N	\N	\N
bd51293a-453a-4da7-b2a0-5dcd8133e100	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	update	Appointment	91bce788-2b3b-4a2b-bb83-62eabc7b2727	{"Date":"2026-02-03T00:00:00-03:00","Time":"07:46","Status":"InProgress","Observation":"doid\\u00F4"}	{"Date":"2026-02-03T00:00:00-03:00","Time":"07:46","Status":"InProgress","Observation":"doid\\u00F4"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T13:57:05.3080527Z	2026-02-03T13:57:05.3080532Z	\N	\N	\N	\N
a8d5a295-4d61-4a4f-bc4d-880a01ef2dee	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	update	Appointment	91bce788-2b3b-4a2b-bb83-62eabc7b2727	{"Date":"2026-02-03T00:00:00-03:00","Time":"07:46","Status":"InProgress","Observation":"doid\\u00F4"}	{"Date":"2026-02-03T00:00:00-03:00","Time":"07:46","Status":"InProgress","Observation":"doid\\u00F4"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T13:57:09.1558376Z	2026-02-03T13:57:09.1558379Z	\N	\N	\N	\N
5311a7ef-ccee-40b9-bc7e-97baea48753d	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	update	Appointment	91bce788-2b3b-4a2b-bb83-62eabc7b2727	{"Date":"2026-02-03T00:00:00-03:00","Time":"07:46","Status":"InProgress","Observation":"doid\\u00F4"}	{"Date":"2026-02-03T00:00:00-03:00","Time":"07:46","Status":"InProgress","Observation":"doid\\u00F4"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T13:57:26.3481936Z	2026-02-03T13:57:26.3481938Z	\N	\N	\N	\N
d5032d58-84e0-4d4a-a090-00f9d3df1218	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	VIEW_CLINICAL_TIMELINE	Patient	0b3b0ee6-1eec-4598-9d30-09442a923ae1	\N	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T14:25:42.0906383Z	2026-02-03T14:25:42.0906385Z	Visualiza├º├úo durante teleconsulta	PRONTUARIO	90000000018	0b3b0ee6-1eec-4598-9d30-09442a923ae1
994109e2-26b1-4e56-a127-d1979c8f2a96	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	d8567e18-665b-4421-9746-27f728456f76	\N	{"RoomName":"d8567e18665b4421974627f728456f76","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T14:31:20.8828840Z	2026-02-03T14:31:20.8828841Z	\N	\N	\N	\N
a1e8f9bd-7d0d-42d4-9ee4-a2bdeacd6468	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	d8567e18-665b-4421-9746-27f728456f76	\N	{"RoomName":"d8567e18665b4421974627f728456f76","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T14:31:40.9275710Z	2026-02-03T14:31:40.9275711Z	\N	\N	\N	\N
e9701a54-9a54-4e29-9527-fc05cbfc4d72	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	jitsi_access	Appointment	91bce788-2b3b-4a2b-bb83-62eabc7b2727	\N	{"RoomName":"91bce7882b3b4a2bbb8362eabc7b2727","IsModerator":true,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T14:31:41.2140020Z	2026-02-03T14:31:41.2140020Z	\N	\N	\N	\N
3906b0ea-4d94-4f1b-8acf-89c3ce4cb252	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	login	User	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	\N	{"Email":"med_aj@telecuidar.com","LoginTime":"2026-02-03T14:37:03.9499254Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T14:37:03.9508227Z	2026-02-03T14:37:03.9508228Z	\N	\N	\N	\N
23a8aac2-19d8-4633-96c3-fa18af5ba68e	\N	login	User	c10c2caa-846b-47a7-84ca-bb128f426772	\N	{"Email":"rec_ma@telecuidar.com","LoginTime":"2026-02-02T14:04:03.6277727Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T14:04:03.6535031Z	2026-02-02T14:04:03.6535034Z	\N	\N	\N	\N
bdf07e5e-ea5e-4186-abcf-4e670364ed51	f00d2c7c-cca1-4758-b64a-740042d900c5	login	User	f00d2c7c-cca1-4758-b64a-740042d900c5	\N	{"Email":"rec_ma@telecuidar.com","LoginTime":"2026-02-03T10:41:51.1184453Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T10:41:51.1195172Z	2026-02-03T10:41:51.1195173Z	\N	\N	\N	\N
db04a5ad-10c1-4c36-bbf8-4a628eac6be1	d61f6fb1-d2cd-4350-b242-003ac3a4464f	login	User	d61f6fb1-d2cd-4350-b242-003ac3a4464f	\N	{"Email":"enf_do@telecuidar.com","LoginTime":"2026-02-03T10:44:51.2313507Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T10:44:51.2314186Z	2026-02-03T10:44:51.2314187Z	\N	\N	\N	\N
6e42d35e-51ec-4b1c-8069-08964c70023b	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	d8567e18-665b-4421-9746-27f728456f76	\N	{"RoomName":"d8567e18665b4421974627f728456f76","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T11:53:09.3535038Z	2026-02-03T11:53:09.3535039Z	\N	\N	\N	\N
3d912421-ab9c-48c2-b68d-f5c75c2edd09	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	d8567e18-665b-4421-9746-27f728456f76	\N	{"RoomName":"d8567e18665b4421974627f728456f76","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T13:02:39.4661643Z	2026-02-03T13:02:39.4661644Z	\N	\N	\N	\N
ca064f95-538d-4939-abb0-43cfb2dfdde7	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	VIEW_CLINICAL_TIMELINE	Patient	0b3b0ee6-1eec-4598-9d30-09442a923ae1	\N	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T13:45:49.2432850Z	2026-02-03T13:45:49.2432856Z	Visualiza├º├úo durante teleconsulta	PRONTUARIO	90000000018	0b3b0ee6-1eec-4598-9d30-09442a923ae1
9ef381bc-1384-4ff8-a8ac-0fcf662cce3c	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	d8567e18-665b-4421-9746-27f728456f76	\N	{"RoomName":"d8567e18665b4421974627f728456f76","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T14:11:25.1563191Z	2026-02-03T14:11:25.1563192Z	\N	\N	\N	\N
14cfa4b0-b67a-4eb0-97f6-7738796876e0	\N	check_in	Appointment	eaa284a6-e621-4f9b-aef9-e7c7b1c1bc81	\N	Paciente Geraldo fez check-in	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T14:04:20.5588316Z	2026-02-02T14:04:20.5588318Z	\N	\N	\N	\N
c077b1e4-b6d5-4cf8-a46a-e967a7ac2cfe	\N	spontaneous_demand_created	Appointment	b87591e2-c072-49d4-ab49-cb5b9b540f64	\N	Demanda espont├ónea criada: Daniela - Psiquiatria (Urg├¬ncia: Red)	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T14:06:23.0579466Z	2026-02-02T14:06:23.0579468Z	\N	\N	\N	\N
e042b698-fd42-46ca-b294-53aa5ddd58a8	\N	spontaneous_demand_created	Appointment	146567c5-c554-4629-ab19-e612b3a84481	\N	Demanda espont├ónea criada: Daniela - Psiquiatria (Urg├¬ncia: Red)	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T14:39:10.8371627Z	2026-02-02T14:39:10.8371628Z	\N	\N	\N	\N
8d2a6ad6-866b-4529-bd25-3958aa551584	\N	login	User	c10c2caa-846b-47a7-84ca-bb128f426772	\N	{"Email":"rec_ma@telecuidar.com","LoginTime":"2026-02-02T16:38:24.5446331Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T16:38:24.5447205Z	2026-02-02T16:38:24.5447206Z	\N	\N	\N	\N
071e8597-4868-4230-8761-ae19753e11ec	\N	spontaneous_demand_created	Appointment	d66905c6-72d4-4c92-b936-617e54f4578c	\N	Demanda espont├ónea criada: Daniel - Psiquiatria (Urg├¬ncia: Red)	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T16:50:46.7661188Z	2026-02-02T16:50:46.7661190Z	\N	\N	\N	\N
863e6033-5ef3-4c7e-a99d-9fdc6be7363a	\N	spontaneous_demand_created	Appointment	4e761ae2-922b-4345-84b5-14e65cdaee8f	\N	Demanda espont├ónea criada: Daniel - Psiquiatria (Urg├¬ncia: Red)	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T16:54:27.5782550Z	2026-02-02T16:54:27.5782552Z	\N	\N	\N	\N
c9f5494f-6096-42f4-bab3-e2804190cc04	\N	login	User	c10c2caa-846b-47a7-84ca-bb128f426772	\N	{"Email":"rec_ma@telecuidar.com","LoginTime":"2026-02-02T17:00:19.9623017Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T17:00:19.9639397Z	2026-02-02T17:00:19.9639398Z	\N	\N	\N	\N
f2a3a874-aaa9-494e-8429-8475dadb2c9d	\N	spontaneous_demand_created	Appointment	5db622d8-35a9-457b-8f71-8fd0e57c5221	\N	Demanda espont├ónea criada: Daniel - Cardiologia (Urg├¬ncia: Red)	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T17:01:46.0063330Z	2026-02-02T17:01:46.0063330Z	\N	\N	\N	\N
0c2a5a71-3ded-47ac-a3c9-cdfc160743c2	\N	spontaneous_demand_created	Appointment	a49e27be-784d-44d1-aab9-cff8c9ab4776	\N	Demanda espont├ónea criada: Daniela - Psiquiatria (Urg├¬ncia: Red)	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T17:05:56.3259326Z	2026-02-02T17:05:56.3259326Z	\N	\N	\N	\N
adf92ea1-f811-463c-a8ed-1528c9018696	\N	spontaneous_demand_created	Appointment	c1529559-0fc6-46d6-a619-95992539928e	\N	Demanda espont├ónea criada: Daniel - Psiquiatria (Urg├¬ncia: Red)	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T17:09:09.7078101Z	2026-02-02T17:09:09.7078101Z	\N	\N	\N	\N
7d8611dc-7f24-4b56-9a59-61cf545d80a2	\N	login	User	cf8ce926-9d3b-4c3d-be8f-e0451631a248	\N	{"Email":"enf_do@telecuidar.com","LoginTime":"2026-02-02T14:05:18.7198535Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T14:05:18.7205115Z	2026-02-02T14:05:18.7205116Z	\N	\N	\N	\N
23640622-95d1-460b-8305-0b141fe4125d	\N	login	User	cf8ce926-9d3b-4c3d-be8f-e0451631a248	\N	{"Email":"enf_do@telecuidar.com","LoginTime":"2026-02-02T14:39:41.8547068Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T14:39:41.8548094Z	2026-02-02T14:39:41.8548094Z	\N	\N	\N	\N
537ca640-3fbd-446e-a85f-a203ced33513	\N	jitsi_access	Appointment	1fdd178f-b7b5-457e-b282-93bdb2841196	\N	{"RoomName":"1fdd178fb7b5457eb28293bdb2841196","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T14:39:59.2721378Z	2026-02-02T14:39:59.2721381Z	\N	\N	\N	\N
b3269235-9c17-414c-8bad-6fc9fbe32c16	\N	jitsi_access	Appointment	3ed9d6e4-1b9c-42db-aa0c-a5568d070576	\N	{"RoomName":"3ed9d6e41b9c42dbaa0ca5568d070576","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T14:40:39.8723475Z	2026-02-02T14:40:39.8723476Z	\N	\N	\N	\N
6ef227b8-845e-4f4d-a29f-93adad2ef71f	\N	jitsi_access	Appointment	3ed9d6e4-1b9c-42db-aa0c-a5568d070576	\N	{"RoomName":"3ed9d6e41b9c42dbaa0ca5568d070576","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T15:02:21.8468969Z	2026-02-02T15:02:21.8468970Z	\N	\N	\N	\N
2edb827c-408d-4b3f-82fc-16e802535dff	\N	jitsi_access	Appointment	3ed9d6e4-1b9c-42db-aa0c-a5568d070576	\N	{"RoomName":"3ed9d6e41b9c42dbaa0ca5568d070576","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T15:02:56.5741287Z	2026-02-02T15:02:56.5741289Z	\N	\N	\N	\N
f117617c-9962-4821-9ed1-06891eb1fed7	\N	jitsi_access	Appointment	3ed9d6e4-1b9c-42db-aa0c-a5568d070576	\N	{"RoomName":"3ed9d6e41b9c42dbaa0ca5568d070576","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T15:03:04.3368306Z	2026-02-02T15:03:04.3368307Z	\N	\N	\N	\N
8acf3ec8-d97a-4071-b030-5adc8f5926c8	\N	login	User	cf8ce926-9d3b-4c3d-be8f-e0451631a248	\N	{"Email":"enf_do@telecuidar.com","LoginTime":"2026-02-02T16:37:39.0344641Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T16:37:39.0359045Z	2026-02-02T16:37:39.0359046Z	\N	\N	\N	\N
8c82b4c5-e690-4186-977f-6898efe7d8a1	\N	login	User	cf8ce926-9d3b-4c3d-be8f-e0451631a248	\N	{"Email":"enf_do@telecuidar.com","LoginTime":"2026-02-02T17:01:20.4339785Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T17:01:20.4340317Z	2026-02-02T17:01:20.4340317Z	\N	\N	\N	\N
2ca32026-1edb-466a-8508-8fd6e0067048	\N	login	User	a9bdce1c-e671-44c7-8279-ed85221fd345	\N	{"Email":"med_aj@telecuidar.com","LoginTime":"2026-02-02T14:07:07.6218233Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T14:07:07.6219166Z	2026-02-02T14:07:07.6219167Z	\N	\N	\N	\N
236e1bbb-2051-4efb-9fa6-d594ff216320	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	login	User	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	\N	{"Email":"med_aj@telecuidar.com","LoginTime":"2026-02-03T10:45:46.7645324Z"}	192.168.18.161	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T10:45:46.7646072Z	2026-02-03T10:45:46.7646073Z	\N	\N	\N	\N
0c82b696-c57e-46a9-ad66-adc32655840f	\N	login	User	7de1764b-bfa2-43cc-a58a-fdee535fef8f	\N	{"Email":"rec_ma@telecuidar.com","LoginTime":"2026-02-02T18:19:58.9265182Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Code/1.108.2 Chrome/142.0.7444.235 Electron/39.2.7 Safari/537.36	2026-02-02T18:19:58.9432765Z	2026-02-02T18:19:58.9432767Z	\N	\N	\N	\N
b55511be-0040-4042-b905-6bccd7492bf5	8bbb6c58-b963-4f67-b001-c8fa41582afd	login	User	8bbb6c58-b963-4f67-b001-c8fa41582afd	\N	{"Email":"adm_ca@telecuidar.com","LoginTime":"2026-02-02T19:44:38.2212926Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 Edg/144.0.0.0	2026-02-02T19:44:38.2540029Z	2026-02-02T19:44:38.2540030Z	\N	\N	\N	\N
b8eb4e3d-1646-4899-b97a-76492c99439d	f00d2c7c-cca1-4758-b64a-740042d900c5	login	User	f00d2c7c-cca1-4758-b64a-740042d900c5	\N	{"Email":"rec_ma@telecuidar.com","LoginTime":"2026-02-02T19:45:21.3952219Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 Edg/144.0.0.0	2026-02-02T19:45:21.3965444Z	2026-02-02T19:45:21.3965444Z	\N	\N	\N	\N
e191a914-0f40-4663-9302-55208ca75c0b	f00d2c7c-cca1-4758-b64a-740042d900c5	login	User	f00d2c7c-cca1-4758-b64a-740042d900c5	\N	{"Email":"rec_ma@telecuidar.com","LoginTime":"2026-02-02T19:47:35.723986Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T19:47:35.7246378Z	2026-02-02T19:47:35.7246382Z	\N	\N	\N	\N
8206e2c7-9ef7-4a21-bc71-a4ecee5274d1	f00d2c7c-cca1-4758-b64a-740042d900c5	spontaneous_demand_created	Appointment	8925fab8-1766-43a6-b41e-6a1d29def06e	\N	Demanda espont├ónea criada: Daniel - Psiquiatria (Urg├¬ncia: Red)	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T20:07:00.8693267Z	2026-02-02T20:07:00.8693269Z	\N	\N	\N	\N
66d4923a-6698-4599-adf6-2ce21094b29b	d61f6fb1-d2cd-4350-b242-003ac3a4464f	login	User	d61f6fb1-d2cd-4350-b242-003ac3a4464f	\N	{"Email":"enf_do@telecuidar.com","LoginTime":"2026-02-02T20:07:54.9236159Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T20:07:54.9237067Z	2026-02-02T20:07:54.9237068Z	\N	\N	\N	\N
376a68a1-e4bf-4852-bf40-997d24c2faa2	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	login	User	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	\N	{"Email":"med_aj@telecuidar.com","LoginTime":"2026-02-02T20:09:08.5178796Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 Edg/144.0.0.0	2026-02-02T20:09:08.5179742Z	2026-02-02T20:09:08.5179743Z	\N	\N	\N	\N
266444e7-266f-4809-a3e4-7caae4f5fa1f	f00d2c7c-cca1-4758-b64a-740042d900c5	spontaneous_demand_created	Appointment	2a4b1801-2fe9-4db3-b482-02a9002ced66	\N	Demanda espont├ónea criada: Daniela - Psiquiatria (Urg├¬ncia: Orange)	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T20:21:44.5714069Z	2026-02-02T20:21:44.5714080Z	\N	\N	\N	\N
ed9ddc8f-9804-4643-a176-48727143e463	d61f6fb1-d2cd-4350-b242-003ac3a4464f	login	User	d61f6fb1-d2cd-4350-b242-003ac3a4464f	\N	{"Email":"enf_do@telecuidar.com","LoginTime":"2026-02-02T21:13:24.333005Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T21:13:24.3506538Z	2026-02-02T21:13:24.3506540Z	\N	\N	\N	\N
5fdbfa74-dcae-4425-9525-bb3de4b20494	f00d2c7c-cca1-4758-b64a-740042d900c5	login	User	f00d2c7c-cca1-4758-b64a-740042d900c5	\N	{"Email":"rec_ma@telecuidar.com","LoginTime":"2026-02-02T21:13:37.4144857Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T21:13:37.4152058Z	2026-02-02T21:13:37.4152060Z	\N	\N	\N	\N
6a83a5ff-6760-4851-82d8-60c8c3a9ae39	d61f6fb1-d2cd-4350-b242-003ac3a4464f	login	User	d61f6fb1-d2cd-4350-b242-003ac3a4464f	\N	{"Email":"enf_do@telecuidar.com","LoginTime":"2026-02-02T22:22:10.3496092Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T22:22:10.3733683Z	2026-02-02T22:22:10.3733686Z	\N	\N	\N	\N
6def4c85-062e-416c-ab15-81db9e43a7cc	f00d2c7c-cca1-4758-b64a-740042d900c5	login	User	f00d2c7c-cca1-4758-b64a-740042d900c5	\N	{"Email":"rec_ma@telecuidar.com","LoginTime":"2026-02-02T22:22:26.7064151Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T22:22:26.7072184Z	2026-02-02T22:22:26.7072185Z	\N	\N	\N	\N
767b3cea-3cdb-4e30-9688-199ab2dbffbf	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	login	User	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	\N	{"Email":"med_aj@telecuidar.com","LoginTime":"2026-02-02T22:22:38.2139328Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 Edg/144.0.0.0	2026-02-02T22:22:38.2148278Z	2026-02-02T22:22:38.2148280Z	\N	\N	\N	\N
77532b3b-4cf6-4e28-a7b1-8bfd30765443	8bbb6c58-b963-4f67-b001-c8fa41582afd	login	User	8bbb6c58-b963-4f67-b001-c8fa41582afd	\N	{"Email":"adm_ca@telecuidar.com","LoginTime":"2026-02-02T22:22:58.0206839Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 Edg/144.0.0.0	2026-02-02T22:22:58.0209276Z	2026-02-02T22:22:58.0209279Z	\N	\N	\N	\N
479839cf-10e7-4cb6-955c-45be4f27ab62	8bbb6c58-b963-4f67-b001-c8fa41582afd	delete	Specialty	57e3b7ef-14fb-4856-a07c-5063c29e174f	{"Name":"Cardiologia","Description":"Especialidade m\\u00E9dica dedicada ao diagn\\u00F3stico e tratamento de doen\\u00E7as do cora\\u00E7\\u00E3o e do sistema circulat\\u00F3rio, incluindo hipertens\\u00E3o, insufici\\u00EAncia card\\u00EDaca, arritmias e doen\\u00E7as coronarianas."}	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 Edg/144.0.0.0	2026-02-02T22:23:39.2767228Z	2026-02-02T22:23:39.2767230Z	\N	\N	\N	\N
fd8537ea-c426-4b99-9d41-ccf6555801ff	8bbb6c58-b963-4f67-b001-c8fa41582afd	login	User	8bbb6c58-b963-4f67-b001-c8fa41582afd	\N	{"Email":"adm_ca@telecuidar.com","LoginTime":"2026-02-02T22:25:58.4209981Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T22:25:58.4210694Z	2026-02-02T22:25:58.4210695Z	\N	\N	\N	\N
ed918a55-4e4a-447f-b861-21ed0b83891f	8bbb6c58-b963-4f67-b001-c8fa41582afd	login	User	8bbb6c58-b963-4f67-b001-c8fa41582afd	\N	{"Email":"adm_ca@telecuidar.com","LoginTime":"2026-02-02T22:41:24.2888185Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T22:41:24.2955969Z	2026-02-02T22:41:24.2955971Z	\N	\N	\N	\N
a8a00749-8aae-40ab-bbfd-42e6dcc76a30	8bbb6c58-b963-4f67-b001-c8fa41582afd	delete	User	22e02d51-3a04-4827-883f-069ad8c3fff7	{"Email":"adm_do@telecuidar.com","Name":"Daniela","LastName":"Ochoa","Role":"ADMIN"}	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T22:41:32.3034843Z	2026-02-02T22:41:32.3034844Z	\N	\N	\N	\N
932361f0-15cd-417a-83b7-930286c1c643	8bbb6c58-b963-4f67-b001-c8fa41582afd	delete	User	4db1e6f6-1124-4e1c-ad48-3a93b94da55f	{"Email":"adm_aj@telecuidar.com","Name":"Ant\\u00F4nio","LastName":"Jorge","Role":"ADMIN"}	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T22:41:51.6213048Z	2026-02-02T22:41:51.6213049Z	\N	\N	\N	\N
e9f834a2-937b-44e2-9205-1818e966a7a5	8bbb6c58-b963-4f67-b001-c8fa41582afd	delete	User	3fe68a95-9ed3-4135-b9af-578fb14ae950	{"Email":"medico.iomt@teste.com","Name":"Dr. IoMT","LastName":"Teste","Role":"PROFESSIONAL"}	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T22:42:01.2551777Z	2026-02-02T22:42:01.2551780Z	\N	\N	\N	\N
e85f057e-830c-4eef-be40-7d3ac38fa889	8bbb6c58-b963-4f67-b001-c8fa41582afd	delete	User	7ab4e3ce-9085-4fc9-902e-daf20cc5ec2e	{"Email":"paciente.iomt@teste.com","Name":"Paciente IoMT","LastName":"Teste","Role":"PATIENT"}	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T22:42:06.2828716Z	2026-02-02T22:42:06.2828717Z	\N	\N	\N	\N
865f1d5a-026e-4d52-a79d-1317ed933827	8bbb6c58-b963-4f67-b001-c8fa41582afd	delete	Specialty	24d7a0ea-adde-436f-97a8-1fffcd87762b	{"Name":"Geriatria","Description":"Sa\\u00FAde da terceira idade"}	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T22:42:19.2019919Z	2026-02-02T22:42:19.2019922Z	\N	\N	\N	\N
7592996d-58bc-4d3c-be84-1bc8531cdd5d	d61f6fb1-d2cd-4350-b242-003ac3a4464f	login	User	d61f6fb1-d2cd-4350-b242-003ac3a4464f	\N	{"Email":"enf_do@telecuidar.com","LoginTime":"2026-02-02T22:47:07.1446687Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T22:47:07.1447417Z	2026-02-02T22:47:07.1447418Z	\N	\N	\N	\N
9aa78224-7587-4cbe-9577-e20cc50eb4d8	d61f6fb1-d2cd-4350-b242-003ac3a4464f	update	Appointment	99eff75b-ee7b-48af-b565-947ad22f1b82	{"Status":"Scheduled"}	{"Status":"CANCELLED"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T22:47:16.7329966Z	2026-02-02T22:47:16.7329967Z	\N	\N	\N	\N
2c527690-4d56-4f59-90f2-0697575f1fea	d61f6fb1-d2cd-4350-b242-003ac3a4464f	update	Appointment	0be20491-ff40-476d-9333-35682e9066b9	{"Status":"Confirmed"}	{"Status":"CANCELLED"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T22:47:19.8264659Z	2026-02-02T22:47:19.8264659Z	\N	\N	\N	\N
a0971118-9b92-4452-ac36-999b3d085765	d61f6fb1-d2cd-4350-b242-003ac3a4464f	update	Appointment	afd118c5-bb3a-4e1c-b3ea-0b4edb4fc6d9	{"Status":"Confirmed"}	{"Status":"CANCELLED"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T22:47:22.0361732Z	2026-02-02T22:47:22.0361733Z	\N	\N	\N	\N
2c6f3244-cc5f-4287-a0a7-149e361770ee	d61f6fb1-d2cd-4350-b242-003ac3a4464f	update	Appointment	0cd17acc-3583-4c2a-89c3-955e249a9a38	{"Status":"Scheduled"}	{"Status":"CANCELLED"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T22:47:23.9552095Z	2026-02-02T22:47:23.9552095Z	\N	\N	\N	\N
73fa8061-9b3e-449b-8138-fd47cbab13b6	d61f6fb1-d2cd-4350-b242-003ac3a4464f	update	Appointment	1091dddf-25b3-4fbe-9d7a-7cfb92c2887a	{"Status":"Confirmed"}	{"Status":"CANCELLED"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T22:47:26.5173506Z	2026-02-02T22:47:26.5173507Z	\N	\N	\N	\N
859b7f0b-2bba-4fd0-966e-0be1b84a1fc6	d61f6fb1-d2cd-4350-b242-003ac3a4464f	update	Appointment	133fc4de-4841-4761-aa7a-7be26cb76d3f	{"Status":"Confirmed"}	{"Status":"CANCELLED"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T22:47:28.8918046Z	2026-02-02T22:47:28.8918046Z	\N	\N	\N	\N
80bc544d-f8a1-41b7-8a28-e8898e370367	d61f6fb1-d2cd-4350-b242-003ac3a4464f	update	Appointment	568fb219-d8cb-45ab-9e4d-f4a2f361ed5e	{"Status":"Scheduled"}	{"Status":"CANCELLED"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T22:47:30.6192010Z	2026-02-02T22:47:30.6192012Z	\N	\N	\N	\N
16ed1ee4-9422-4df4-a5bb-4a51f2fdd279	d61f6fb1-d2cd-4350-b242-003ac3a4464f	update	Appointment	d222fb2d-17f9-42a1-8717-adf730eeb574	{"Status":"Confirmed"}	{"Status":"CANCELLED"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T22:47:32.3527293Z	2026-02-02T22:47:32.3527296Z	\N	\N	\N	\N
a0a20276-0314-4869-90a8-a0e7ca2bccb1	d61f6fb1-d2cd-4350-b242-003ac3a4464f	update	Appointment	54e7fdb1-b598-4417-9b11-ab2462af7e99	{"Status":"Confirmed"}	{"Status":"CANCELLED"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T22:47:34.0859437Z	2026-02-02T22:47:34.0859437Z	\N	\N	\N	\N
ec650df3-8556-4ef7-a85d-559184d66698	d61f6fb1-d2cd-4350-b242-003ac3a4464f	update	Appointment	d6e5c10f-b702-44b1-ac94-e308a4f8c233	{"Status":"Scheduled"}	{"Status":"CANCELLED"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T22:47:36.1067930Z	2026-02-02T22:47:36.1067931Z	\N	\N	\N	\N
a92a319e-6fd5-45c0-ae1c-aaa0b6396fb3	d61f6fb1-d2cd-4350-b242-003ac3a4464f	update	Appointment	4945bf6b-4c1a-42a3-ad1b-bc3e530746b2	{"Status":"Confirmed"}	{"Status":"CANCELLED"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T22:47:41.6052164Z	2026-02-02T22:47:41.6052164Z	\N	\N	\N	\N
06ba4d9e-6890-4f3e-b10d-81852c5ca9a3	d61f6fb1-d2cd-4350-b242-003ac3a4464f	update	Appointment	94e30dbf-4814-4a20-bf67-adbb1a0e7731	{"Status":"Scheduled"}	{"Status":"CANCELLED"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T22:47:44.7526973Z	2026-02-02T22:47:44.7526975Z	\N	\N	\N	\N
0547d10e-c900-451d-9118-b928f85cab72	d61f6fb1-d2cd-4350-b242-003ac3a4464f	update	Appointment	f3c92cf7-9e01-4920-a54f-6c29c9e5a51d	{"Status":"Scheduled"}	{"Status":"CANCELLED"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T22:47:46.5015058Z	2026-02-02T22:47:46.5015058Z	\N	\N	\N	\N
cf2099b2-36ba-443f-aebb-d0aee9b8f9eb	d61f6fb1-d2cd-4350-b242-003ac3a4464f	update	Appointment	29891c6f-37cd-4af8-9149-6208848b04db	{"Status":"Scheduled"}	{"Status":"CANCELLED"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T22:47:49.2664746Z	2026-02-02T22:47:49.2664748Z	\N	\N	\N	\N
95d7e713-6130-46c0-9d1b-30e63d5c4c67	d61f6fb1-d2cd-4350-b242-003ac3a4464f	update	Appointment	e8625e20-05bf-460e-938d-81cae2b261f8	{"Status":"Confirmed"}	{"Status":"CANCELLED"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T22:47:55.6858866Z	2026-02-02T22:47:55.6858867Z	\N	\N	\N	\N
ecea9101-bd49-4c53-9211-65216bba9b29	d61f6fb1-d2cd-4350-b242-003ac3a4464f	update	Appointment	189f43bf-cd5f-4301-af10-327a7bff846f	{"Status":"Scheduled"}	{"Status":"CANCELLED"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T22:47:57.8917546Z	2026-02-02T22:47:57.8917548Z	\N	\N	\N	\N
082dc0f6-da90-4cf2-a878-4807b2093c31	d61f6fb1-d2cd-4350-b242-003ac3a4464f	update	Appointment	19d119d8-45f4-4fd1-be7a-f002024a9b4b	{"Status":"Scheduled"}	{"Status":"CANCELLED"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T22:48:05.4883863Z	2026-02-02T22:48:05.4883864Z	\N	\N	\N	\N
4ab116e8-2fb6-46eb-b7cc-42d7cc1985f9	d61f6fb1-d2cd-4350-b242-003ac3a4464f	update	Appointment	23dd1d3c-adc6-4e79-9423-468d4be4e7c8	{"Status":"Confirmed"}	{"Status":"CANCELLED"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T22:48:07.4213486Z	2026-02-02T22:48:07.4213487Z	\N	\N	\N	\N
3bcc756c-24ea-4c7e-a854-25180310c2f4	d61f6fb1-d2cd-4350-b242-003ac3a4464f	update	Appointment	26af901a-1bd9-4ee0-aeb2-477d36d08d5d	{"Status":"Confirmed"}	{"Status":"CANCELLED"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T22:48:09.2236840Z	2026-02-02T22:48:09.2236841Z	\N	\N	\N	\N
a54be15e-7673-4974-9423-38449d3de837	d61f6fb1-d2cd-4350-b242-003ac3a4464f	update	Appointment	5cf82b31-4783-45e4-92e4-426df6484acd	{"Status":"Confirmed"}	{"Status":"CANCELLED"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T22:48:10.8362665Z	2026-02-02T22:48:10.8362665Z	\N	\N	\N	\N
7391dcf8-14c4-48ee-8b52-f34b50285961	d61f6fb1-d2cd-4350-b242-003ac3a4464f	update	Appointment	f293e7e6-d134-4959-80d1-8bbe7fa24ea7	{"Status":"Scheduled"}	{"Status":"CANCELLED"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T22:48:23.5785151Z	2026-02-02T22:48:23.5785152Z	\N	\N	\N	\N
30df5a13-9e2e-4fdb-a885-0f20882e4984	d61f6fb1-d2cd-4350-b242-003ac3a4464f	update	Appointment	59118121-9fdb-413d-a8fd-227228836e94	{"Status":"Scheduled"}	{"Status":"CANCELLED"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T22:48:25.2990788Z	2026-02-02T22:48:25.2990790Z	\N	\N	\N	\N
1f6fae60-2a43-4efa-a55c-7355a88a9d14	d61f6fb1-d2cd-4350-b242-003ac3a4464f	update	Appointment	59278760-0265-4088-ae5d-2b6205711ebd	{"Status":"Scheduled"}	{"Status":"CANCELLED"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T22:48:26.9257777Z	2026-02-02T22:48:26.9257782Z	\N	\N	\N	\N
98f171c0-d8c8-4f15-9e7d-dca207397477	d61f6fb1-d2cd-4350-b242-003ac3a4464f	update	Appointment	d40fb5e7-5dee-4ede-8f9d-66e40afedcbe	{"Status":"Confirmed"}	{"Status":"CANCELLED"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T22:48:28.6089538Z	2026-02-02T22:48:28.6089539Z	\N	\N	\N	\N
d545bc00-c2b1-435c-b35e-01585f5878f9	d61f6fb1-d2cd-4350-b242-003ac3a4464f	update	Appointment	d719b4aa-cd7c-4d1c-8f07-4c68668b7637	{"Status":"Confirmed"}	{"Status":"CANCELLED"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T22:48:30.2715327Z	2026-02-02T22:48:30.2715329Z	\N	\N	\N	\N
c1b4b3d4-ddea-4376-b449-ef818c2d212e	d61f6fb1-d2cd-4350-b242-003ac3a4464f	update	Appointment	dc116d91-305a-4a1c-bd68-9edb23f7f4e2	{"Status":"Scheduled"}	{"Status":"CANCELLED"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T22:48:32.3453586Z	2026-02-02T22:48:32.3453587Z	\N	\N	\N	\N
c6bff456-0b47-4b94-8dad-96f850c055d5	d61f6fb1-d2cd-4350-b242-003ac3a4464f	update	Appointment	92e06df0-6d34-48fc-afda-4c1607a9cea6	{"Status":"Scheduled"}	{"Status":"CANCELLED"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T22:48:34.8429995Z	2026-02-02T22:48:34.8429996Z	\N	\N	\N	\N
e3d9f3ef-6e4d-480c-92b3-04b121eb5c3a	d61f6fb1-d2cd-4350-b242-003ac3a4464f	update	Appointment	9d39d783-9cc7-4d49-aae4-e8a636da4525	{"Status":"Confirmed"}	{"Status":"CANCELLED"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T22:48:36.7702476Z	2026-02-02T22:48:36.7702477Z	\N	\N	\N	\N
50ed0d63-b3ad-4c66-a80b-a72b0eab44fc	d61f6fb1-d2cd-4350-b242-003ac3a4464f	update	Appointment	deb50906-dfcf-4705-9866-cb0b1fa0a6cf	{"Status":"Scheduled"}	{"Status":"CANCELLED"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T22:48:12.4907079Z	2026-02-02T22:48:12.4907081Z	\N	\N	\N	\N
301d1c95-c53b-4e0f-9fd1-7d842f71f649	d61f6fb1-d2cd-4350-b242-003ac3a4464f	update	Appointment	688626ce-e97b-43b2-9c9c-739b2ce81692	{"Status":"Confirmed"}	{"Status":"CANCELLED"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T22:48:15.4500982Z	2026-02-02T22:48:15.4500985Z	\N	\N	\N	\N
a938d59a-516a-4d52-988d-19bbedc4f498	d61f6fb1-d2cd-4350-b242-003ac3a4464f	update	Appointment	225c3067-4032-4e82-be08-290453068672	{"Status":"Scheduled"}	{"Status":"CANCELLED"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T22:48:18.8165788Z	2026-02-02T22:48:18.8165791Z	\N	\N	\N	\N
f247949b-11b3-4a4e-988a-e08727464aeb	d61f6fb1-d2cd-4350-b242-003ac3a4464f	update	Appointment	c764eac2-7fbb-4b1c-86bf-8adbb44645ae	{"Status":"Scheduled"}	{"Status":"CANCELLED"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T22:48:20.6646872Z	2026-02-02T22:48:20.6646872Z	\N	\N	\N	\N
15e02dbb-1ca2-4039-b9e2-f048bc9d51b2	f00d2c7c-cca1-4758-b64a-740042d900c5	spontaneous_demand_created	Appointment	91bce788-2b3b-4a2b-bb83-62eabc7b2727	\N	Demanda espont├ónea criada: Daniela - Psiquiatria (Urg├¬ncia: Red)	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T10:46:48.9702409Z	2026-02-03T10:46:48.9702410Z	\N	\N	\N	\N
d7da619c-aaa2-41b4-b0e3-741e94bf7a01	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	d8567e18-665b-4421-9746-27f728456f76	\N	{"RoomName":"d8567e18665b4421974627f728456f76","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T11:55:51.8898257Z	2026-02-03T11:55:51.8898258Z	\N	\N	\N	\N
75521d27-2d12-4b36-a3de-7fbfbe7e8673	d61f6fb1-d2cd-4350-b242-003ac3a4464f	login	User	d61f6fb1-d2cd-4350-b242-003ac3a4464f	\N	{"Email":"enf_do@telecuidar.com","LoginTime":"2026-02-03T11:56:15.1443773Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T11:56:15.1444695Z	2026-02-03T11:56:15.1444695Z	\N	\N	\N	\N
a4f7486b-87a7-4794-8f5e-c2b879613905	d61f6fb1-d2cd-4350-b242-003ac3a4464f	login	User	d61f6fb1-d2cd-4350-b242-003ac3a4464f	\N	{"Email":"enf_do@telecuidar.com","LoginTime":"2026-02-03T11:57:07.7554233Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T11:57:07.7555361Z	2026-02-03T11:57:07.7555362Z	\N	\N	\N	\N
33d6ae53-a4fa-4ec1-ae3d-01d4d6c5d281	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	d8567e18-665b-4421-9746-27f728456f76	\N	{"RoomName":"d8567e18665b4421974627f728456f76","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T13:29:14.3234173Z	2026-02-03T13:29:14.3234176Z	\N	\N	\N	\N
6ebff242-b3b5-4a14-bf5e-7608ebc15c70	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	login	User	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	\N	{"Email":"med_aj@telecuidar.com","LoginTime":"2026-02-03T13:31:56.3230731Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T13:31:56.3268834Z	2026-02-03T13:31:56.3268836Z	\N	\N	\N	\N
e2cd0e8c-2b50-46e4-94a5-619b5e62dd2e	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	d8567e18-665b-4421-9746-27f728456f76	\N	{"RoomName":"d8567e18665b4421974627f728456f76","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T13:52:04.7875373Z	2026-02-03T13:52:04.7875374Z	\N	\N	\N	\N
3ae9813a-e101-4d80-b85f-ad1d2d32b112	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	jitsi_access	Appointment	91bce788-2b3b-4a2b-bb83-62eabc7b2727	\N	{"RoomName":"91bce7882b3b4a2bbb8362eabc7b2727","IsModerator":true,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T13:52:04.9947936Z	2026-02-03T13:52:04.9947937Z	\N	\N	\N	\N
867fc292-6ea0-4d60-aec3-09c9635a3421	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	jitsi_access	Appointment	91bce788-2b3b-4a2b-bb83-62eabc7b2727	\N	{"RoomName":"91bce7882b3b4a2bbb8362eabc7b2727","IsModerator":true,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T13:52:22.9546922Z	2026-02-03T13:52:22.9546924Z	\N	\N	\N	\N
d5521bd3-f55c-4660-a41d-447f44e07d28	d61f6fb1-d2cd-4350-b242-003ac3a4464f	login	User	d61f6fb1-d2cd-4350-b242-003ac3a4464f	\N	{"Email":"enf_do@telecuidar.com","LoginTime":"2026-02-03T14:11:58.5409209Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T14:11:58.5421124Z	2026-02-03T14:11:58.5421125Z	\N	\N	\N	\N
4284c93b-1555-42c4-9105-eb4233175101	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	d8567e18-665b-4421-9746-27f728456f76	\N	{"RoomName":"d8567e18665b4421974627f728456f76","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T14:27:41.2181089Z	2026-02-03T14:27:41.2181090Z	\N	\N	\N	\N
1c9f8fc6-2ca1-4885-82eb-9c53f9d6b5e2	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	jitsi_access	Appointment	91bce788-2b3b-4a2b-bb83-62eabc7b2727	\N	{"RoomName":"91bce7882b3b4a2bbb8362eabc7b2727","IsModerator":true,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T14:31:30.7974046Z	2026-02-03T14:31:30.7974046Z	\N	\N	\N	\N
cb4fdd48-8c12-4a27-9b48-a38852079fa2	d61f6fb1-d2cd-4350-b242-003ac3a4464f	login	User	d61f6fb1-d2cd-4350-b242-003ac3a4464f	\N	{"Email":"enf_do@telecuidar.com","LoginTime":"2026-02-03T14:35:40.3219757Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T14:35:40.3233893Z	2026-02-03T14:35:40.3233894Z	\N	\N	\N	\N
0fa63dd7-f12c-42e5-8418-8c623dfd100a	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	d8567e18-665b-4421-9746-27f728456f76	\N	{"RoomName":"d8567e18665b4421974627f728456f76","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T14:35:45.0338308Z	2026-02-03T14:35:45.0338311Z	\N	\N	\N	\N
601b4d07-ab02-4ee5-b65e-e17ed7ea64c4	d61f6fb1-d2cd-4350-b242-003ac3a4464f	update	Appointment	a540b686-088f-4530-99be-62f3941af67a	{"Status":"Confirmed"}	{"Status":"CANCELLED"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T22:48:38.4439433Z	2026-02-02T22:48:38.4439434Z	\N	\N	\N	\N
b351dbd1-840b-4e82-a942-ee54ebf2a8f7	d61f6fb1-d2cd-4350-b242-003ac3a4464f	update	Appointment	004bf064-8929-4475-89bf-291c3137c8ad	{"Status":"Scheduled"}	{"Status":"CANCELLED"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T22:48:41.6475864Z	2026-02-02T22:48:41.6475864Z	\N	\N	\N	\N
316d2aaf-8845-4663-8a02-c5b95aa79030	d61f6fb1-d2cd-4350-b242-003ac3a4464f	update	Appointment	06673576-3868-4f13-a479-fd42af0f6bed	{"Status":"Scheduled"}	{"Status":"CANCELLED"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T22:48:44.1611223Z	2026-02-02T22:48:44.1611224Z	\N	\N	\N	\N
d1686545-7069-4579-87a7-2221e87cd4fa	d61f6fb1-d2cd-4350-b242-003ac3a4464f	update	Appointment	5eefd91c-f9d3-47a4-be4f-17fe6fcf2104	{"Status":"Scheduled"}	{"Status":"CANCELLED"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T22:48:47.0658847Z	2026-02-02T22:48:47.0658847Z	\N	\N	\N	\N
45cf82bf-cbc3-4c6c-b4d5-bd135570baf0	d61f6fb1-d2cd-4350-b242-003ac3a4464f	update	Appointment	f5203da4-44a1-4d08-bf75-bed0c98cda8f	{"Status":"Confirmed"}	{"Status":"CANCELLED"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T22:48:50.6643059Z	2026-02-02T22:48:50.6643061Z	\N	\N	\N	\N
e5fd1bfa-3d54-4c1f-81c1-58a201c8d537	d61f6fb1-d2cd-4350-b242-003ac3a4464f	update	Appointment	63eeaef6-4f8b-4753-8431-b5256e79e804	{"Status":"Scheduled"}	{"Status":"CANCELLED"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T22:48:52.8933488Z	2026-02-02T22:48:52.8933489Z	\N	\N	\N	\N
63d31762-7c8f-4802-99c2-1e8a195fd242	d61f6fb1-d2cd-4350-b242-003ac3a4464f	update	Appointment	3963eebd-619d-4fea-9dba-2a0418c70de0	{"Status":"Scheduled"}	{"Status":"CANCELLED"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T22:48:55.2452997Z	2026-02-02T22:48:55.2452997Z	\N	\N	\N	\N
0d6bd6cd-dfa7-4fa9-9519-96391fb244df	d61f6fb1-d2cd-4350-b242-003ac3a4464f	update	Appointment	64f0806b-3086-46fa-8e37-de72e773ee55	{"Status":"Confirmed"}	{"Status":"CANCELLED"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T22:54:27.7082369Z	2026-02-02T22:54:27.7082370Z	\N	\N	\N	\N
6bd41cd9-e46d-47e4-af94-3a7513d90ed9	d61f6fb1-d2cd-4350-b242-003ac3a4464f	update	Appointment	4454ff3a-e9e4-4b74-ba84-e18a4ab72391	{"Status":"Scheduled"}	{"Status":"CANCELLED"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T22:54:30.5857116Z	2026-02-02T22:54:30.5857116Z	\N	\N	\N	\N
ba0e5e0a-a916-4a73-85bb-485d763da2af	d61f6fb1-d2cd-4350-b242-003ac3a4464f	update	Appointment	21990367-bbb8-498f-9ce5-5c8d85be22b7	{"Status":"Scheduled"}	{"Status":"CANCELLED"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T22:54:33.8093275Z	2026-02-02T22:54:33.8093276Z	\N	\N	\N	\N
f3cf6f97-52a3-4479-8f0d-e12a52d68e70	d61f6fb1-d2cd-4350-b242-003ac3a4464f	update	Appointment	22847fd4-4702-4698-84a2-acb1a7ae4fa5	{"Status":"Scheduled"}	{"Status":"CANCELLED"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T22:54:36.6922955Z	2026-02-02T22:54:36.6922956Z	\N	\N	\N	\N
24a63d9f-a69b-464e-af1e-589b5ea77c89	d61f6fb1-d2cd-4350-b242-003ac3a4464f	update	Appointment	12894128-8734-435d-ac9c-c1462b506ebc	{"Status":"Confirmed"}	{"Status":"CANCELLED"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T22:54:39.5420186Z	2026-02-02T22:54:39.5420186Z	\N	\N	\N	\N
bc0ad21f-fc7a-46a5-8e56-2f6735b90b62	d61f6fb1-d2cd-4350-b242-003ac3a4464f	update	Appointment	61c0c4ec-6e26-4c2c-a1d2-066934b99e6f	{"Status":"Scheduled"}	{"Status":"CANCELLED"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T22:54:56.4006900Z	2026-02-02T22:54:56.4006907Z	\N	\N	\N	\N
256072e7-fa5b-46f2-858c-9fed57c006ad	d61f6fb1-d2cd-4350-b242-003ac3a4464f	update	Appointment	9fe4d47d-bb0d-4db0-9bc7-a726f6029278	{"Status":"CheckedIn"}	{"Status":"CANCELLED"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T22:55:09.1967585Z	2026-02-02T22:55:09.1967586Z	\N	\N	\N	\N
e9f6db93-daeb-4288-b440-0c36b09c8fbb	d61f6fb1-d2cd-4350-b242-003ac3a4464f	update	Appointment	8925fab8-1766-43a6-b41e-6a1d29def06e	{"Status":"CheckedIn"}	{"Status":"CANCELLED"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T22:55:12.3868317Z	2026-02-02T22:55:12.3868317Z	\N	\N	\N	\N
11dfb8dd-f888-4659-8637-0c52f4f53d41	d61f6fb1-d2cd-4350-b242-003ac3a4464f	update	Appointment	2a4b1801-2fe9-4db3-b482-02a9002ced66	{"Status":"CheckedIn"}	{"Status":"CANCELLED"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-02T22:55:16.2771657Z	2026-02-02T22:55:16.2771657Z	\N	\N	\N	\N
e160c957-e0a1-4f08-8659-eb1fec192ebf	8bbb6c58-b963-4f67-b001-c8fa41582afd	delete	User	6a938ac9-9539-4cba-943c-7f44301c0abd	{"Email":"adm_gt@telecuidar.com","Name":"Geraldo","LastName":"Tadeu","Role":"ADMIN"}	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 Edg/144.0.0.0	2026-02-02T23:00:25.6662084Z	2026-02-02T23:00:25.6662085Z	\N	\N	\N	\N
049d154a-c81c-4bc5-bc8b-862f73b2ab93	8bbb6c58-b963-4f67-b001-c8fa41582afd	delete	User	d531bf12-5833-499d-9cc8-7e584dd9e7d2	{"Email":"enf_dc@telecuidar.com","Name":"Daniel","LastName":"Carrara","Role":"ASSISTANT"}	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 Edg/144.0.0.0	2026-02-02T23:00:33.4216636Z	2026-02-02T23:00:33.4216636Z	\N	\N	\N	\N
10d5155d-c211-4564-9078-aca2ab4289af	8bbb6c58-b963-4f67-b001-c8fa41582afd	delete	User	dc0a3e05-c559-4be2-8c0a-2b1be593df42	{"Email":"enf_ca@telecuidar.com","Name":"Cl\\u00E1udio","LastName":"Amantino","Role":"ASSISTANT"}	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 Edg/144.0.0.0	2026-02-02T23:01:01.3319014Z	2026-02-02T23:01:01.3319014Z	\N	\N	\N	\N
4d3ed66c-7a20-4344-893c-3e4de73d8b09	8bbb6c58-b963-4f67-b001-c8fa41582afd	delete	User	0acec268-9b11-49b9-a2d6-387cc0568277	{"Email":"adm_dc@telecuidar.com","Name":"Daniel","LastName":"Carrara","Role":"ADMIN"}	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 Edg/144.0.0.0	2026-02-02T23:01:08.0457222Z	2026-02-02T23:01:08.0457223Z	\N	\N	\N	\N
2719751e-92a6-489b-9910-2728c0935c24	8bbb6c58-b963-4f67-b001-c8fa41582afd	delete	User	4357cc88-790f-4965-9c8e-33f794dbe00b	{"Email":"enf_gt@telecuidar.com","Name":"Geraldo","LastName":"Tadeu","Role":"ASSISTANT"}	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 Edg/144.0.0.0	2026-02-02T23:02:06.4530960Z	2026-02-02T23:02:06.4530962Z	\N	\N	\N	\N
51d81e1c-0755-4e49-90d1-418a29663450	\N	login	User	9406a1f0-1f86-48af-8259-234bf7e72571	\N	{"Email":"assist@assist.com","LoginTime":"2026-02-01T18:47:00.0544479Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-01T18:47:00.0551969Z	2026-02-01T18:47:00.0551969Z	\N	\N	\N	\N
3b8e29bb-c135-4194-9926-807dba7fa1be	\N	jitsi_access	Appointment	9fe4d47d-bb0d-4db0-9bc7-a726f6029278	\N	{"RoomName":"9fe4d47dbb0d4db09bc7a726f6029278","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-01T19:05:28.1656886Z	2026-02-01T19:05:28.1656887Z	\N	\N	\N	\N
d5d96c04-6200-4db1-bc39-f5661ff8f5d7	\N	jitsi_access	Appointment	9fe4d47d-bb0d-4db0-9bc7-a726f6029278	\N	{"RoomName":"9fe4d47dbb0d4db09bc7a726f6029278","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-01T19:05:40.5425968Z	2026-02-01T19:05:40.5425969Z	\N	\N	\N	\N
a6c33755-166c-4d26-9ca4-583335b1c91c	\N	jitsi_access	Appointment	9fe4d47d-bb0d-4db0-9bc7-a726f6029278	\N	{"RoomName":"9fe4d47dbb0d4db09bc7a726f6029278","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-01T19:05:49.1410259Z	2026-02-01T19:05:49.1410260Z	\N	\N	\N	\N
ad239e1f-b536-4113-bfeb-349c6523f901	\N	login	User	9406a1f0-1f86-48af-8259-234bf7e72571	\N	{"Email":"assist@assist.com","LoginTime":"2026-02-01T20:15:19.2174876Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-01T20:15:19.2187167Z	2026-02-01T20:15:19.2187170Z	\N	\N	\N	\N
4d52d0c3-2ecb-4b6d-a977-6e78442a65ff	\N	jitsi_access	Appointment	9fe4d47d-bb0d-4db0-9bc7-a726f6029278	\N	{"RoomName":"9fe4d47dbb0d4db09bc7a726f6029278","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-01T20:15:24.3083759Z	2026-02-01T20:15:24.3083760Z	\N	\N	\N	\N
53f0a5ad-c253-4b4e-b291-830a3dcc8a87	\N	jitsi_access	Appointment	9fe4d47d-bb0d-4db0-9bc7-a726f6029278	\N	{"RoomName":"9fe4d47dbb0d4db09bc7a726f6029278","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-01T20:16:23.4246108Z	2026-02-01T20:16:23.4246108Z	\N	\N	\N	\N
5028f5d7-b904-4fb1-b92e-54b0a8c54b8f	\N	jitsi_access	Appointment	9fe4d47d-bb0d-4db0-9bc7-a726f6029278	\N	{"RoomName":"9fe4d47dbb0d4db09bc7a726f6029278","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-01T20:20:12.7572342Z	2026-02-01T20:20:12.7572343Z	\N	\N	\N	\N
72d5581a-b4fb-4bd8-b33b-08b3541b2427	8bbb6c58-b963-4f67-b001-c8fa41582afd	delete	User	9406a1f0-1f86-48af-8259-234bf7e72571	{"Email":"assist@assist.com","Name":"Assistente","LastName":"De Teste","Role":"ASSISTANT"}	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 Edg/144.0.0.0	2026-02-02T23:03:03.5091191Z	2026-02-02T23:03:03.5091191Z	\N	\N	\N	\N
07fbe9c6-f179-4647-afbd-866af745d9b8	8bbb6c58-b963-4f67-b001-c8fa41582afd	delete	User	9c798c37-e7e5-4641-9f5e-72836d1a0541	{"Email":"enf_aj@telecuidar.com","Name":"Ant\\u00F4nio","LastName":"Jorge","Role":"ASSISTANT"}	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 Edg/144.0.0.0	2026-02-02T23:04:15.3257615Z	2026-02-02T23:04:15.3257617Z	\N	\N	\N	\N
aa382aa8-9d74-41c7-8175-96fd5601aed0	8bbb6c58-b963-4f67-b001-c8fa41582afd	delete	Schedule	9b0a0d75-abb5-4845-b09f-200c35815046	{"ProfessionalId":"a06cbf1d-2661-49ff-bbfb-0041b02dae5e","ValidityStartDate":"2026-02-01","ValidityEndDate":"2026-03-31","Status":"Active"}	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 Edg/144.0.0.0	2026-02-02T23:05:49.7232008Z	2026-02-02T23:05:49.7232008Z	\N	\N	\N	\N
3d2d61e0-522d-4410-8061-721981075e09	8bbb6c58-b963-4f67-b001-c8fa41582afd	delete	Schedule	75daa463-7203-4cf3-b48d-d471c391732f	{"ProfessionalId":"747a3c9b-f2ac-4508-aa2c-74114e8c4ee5","ValidityStartDate":"2026-02-01","ValidityEndDate":"2026-03-31","Status":"Active"}	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 Edg/144.0.0.0	2026-02-02T23:05:53.8981847Z	2026-02-02T23:05:53.8981850Z	\N	\N	\N	\N
a12e728f-f0f3-4014-92e2-3e6472f3521e	8bbb6c58-b963-4f67-b001-c8fa41582afd	delete	Schedule	7a9eb5f2-3391-49f2-b86b-5cf1b05768e6	{"ProfessionalId":"d6632c0a-fcf3-4a19-a812-2b68ff4416a3","ValidityStartDate":"2026-02-01","ValidityEndDate":"2026-03-31","Status":"Active"}	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 Edg/144.0.0.0	2026-02-02T23:05:57.1787764Z	2026-02-02T23:05:57.1787765Z	\N	\N	\N	\N
da149721-c312-4ff6-a0d2-2a33dba72c80	8bbb6c58-b963-4f67-b001-c8fa41582afd	delete	Schedule	6e28af4d-3655-436a-bc6c-7cfe7720093a	{"ProfessionalId":"80a84ea3-f080-46ef-8aa9-83f778c556f1","ValidityStartDate":"2026-02-01","ValidityEndDate":"2026-03-31","Status":"Active"}	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 Edg/144.0.0.0	2026-02-02T23:05:59.6442091Z	2026-02-02T23:05:59.6442093Z	\N	\N	\N	\N
1eedb9b2-504a-4ebc-a015-bcad64d47de3	8bbb6c58-b963-4f67-b001-c8fa41582afd	delete	Schedule	0d9fdc60-4d3d-4a3c-a775-4be152d67c49	{"ProfessionalId":"6f3a6731-435d-4f76-b725-42c993f2797c","ValidityStartDate":"2026-02-01","ValidityEndDate":"2026-03-31","Status":"Active"}	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 Edg/144.0.0.0	2026-02-02T23:06:02.1160003Z	2026-02-02T23:06:02.1160004Z	\N	\N	\N	\N
aa84b0b8-baf5-440d-b904-d8071cfbf987	8bbb6c58-b963-4f67-b001-c8fa41582afd	delete	Schedule	a7590ad6-c3f5-4fc2-9390-a98f7e9d79c4	{"ProfessionalId":"aaaa5050-dfc2-42d9-a849-ab9a8b354cac","ValidityStartDate":"2026-02-01","Status":"Active"}	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 Edg/144.0.0.0	2026-02-02T23:06:04.5660099Z	2026-02-02T23:06:04.5660101Z	\N	\N	\N	\N
fe660f78-5e9d-47bb-b8b8-35cccbbf322d	f00d2c7c-cca1-4758-b64a-740042d900c5	login	User	f00d2c7c-cca1-4758-b64a-740042d900c5	\N	{"Email":"rec_ma@telecuidar.com","LoginTime":"2026-02-03T02:03:55.2704563Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T02:03:55.2705739Z	2026-02-03T02:03:55.2705740Z	\N	\N	\N	\N
287902bf-febc-40ed-878d-2847faf4fc86	8bbb6c58-b963-4f67-b001-c8fa41582afd	update	Specialty	0300914f-9def-4fab-9ef0-4325f02deb17	{"Name":"Cardiologia","Description":"Especialidade m\\u00E9dica dedicada ao diagn\\u00F3stico e tratamento de doen\\u00E7as do cora\\u00E7\\u00E3o e do sistema circulat\\u00F3rio, incluindo hipertens\\u00E3o, insufici\\u00EAncia card\\u00EDaca, arritmias e doen\\u00E7as coronarianas.","Status":"Active"}	{"Name":"Cardiologia","Description":"Especialidade m\\u00E9dica dedicada ao diagn\\u00F3stico e tratamento de doen\\u00E7as do cora\\u00E7\\u00E3o e do sistema circulat\\u00F3rio, incluindo hipertens\\u00E3o, insufici\\u00EAncia card\\u00EDaca, arritmias e doen\\u00E7as coronarianas.","Status":"Inactive"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 Edg/144.0.0.0	2026-02-02T23:08:08.7534755Z	2026-02-02T23:08:08.7534756Z	\N	\N	\N	\N
44b6afd5-8b27-430f-933f-2b8ca09c6e8b	8bbb6c58-b963-4f67-b001-c8fa41582afd	update	Specialty	7f5a938e-3ae9-4f88-a984-1293fd5e1dcf	{"Name":"Cardiologia","Description":"Especialidade m\\u00E9dica dedicada ao diagn\\u00F3stico e tratamento de doen\\u00E7as do cora\\u00E7\\u00E3o e do sistema circulat\\u00F3rio, incluindo hipertens\\u00E3o, insufici\\u00EAncia card\\u00EDaca, arritmias e doen\\u00E7as coronarianas.","Status":"Active"}	{"Name":"Cardiologia","Description":"Especialidade m\\u00E9dica dedicada ao diagn\\u00F3stico e tratamento de doen\\u00E7as do cora\\u00E7\\u00E3o e do sistema circulat\\u00F3rio, incluindo hipertens\\u00E3o, insufici\\u00EAncia card\\u00EDaca, arritmias e doen\\u00E7as coronarianas.","Status":"Inactive"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 Edg/144.0.0.0	2026-02-02T23:08:17.2421477Z	2026-02-02T23:08:17.2421477Z	\N	\N	\N	\N
f11c7b76-07b6-40c1-b11e-c5b790addab6	8bbb6c58-b963-4f67-b001-c8fa41582afd	update	Specialty	7f5a938e-3ae9-4f88-a984-1293fd5e1dcf	{"Name":"Cardiologia","Description":"Especialidade m\\u00E9dica dedicada ao diagn\\u00F3stico e tratamento de doen\\u00E7as do cora\\u00E7\\u00E3o e do sistema circulat\\u00F3rio, incluindo hipertens\\u00E3o, insufici\\u00EAncia card\\u00EDaca, arritmias e doen\\u00E7as coronarianas.","Status":"Inactive"}	{"Name":"Cardiologia","Description":"Especialidade m\\u00E9dica dedicada ao diagn\\u00F3stico e tratamento de doen\\u00E7as do cora\\u00E7\\u00E3o e do sistema circulat\\u00F3rio, incluindo hipertens\\u00E3o, insufici\\u00EAncia card\\u00EDaca, arritmias e doen\\u00E7as coronarianas.","Status":"Active"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 Edg/144.0.0.0	2026-02-02T23:08:47.5159152Z	2026-02-02T23:08:47.5159153Z	\N	\N	\N	\N
736e0655-ebce-4698-a569-69bd82c61aac	8bbb6c58-b963-4f67-b001-c8fa41582afd	login	User	8bbb6c58-b963-4f67-b001-c8fa41582afd	\N	{"Email":"adm_ca@telecuidar.com","LoginTime":"2026-02-02T23:25:51.8569313Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 Edg/144.0.0.0	2026-02-02T23:25:51.8652752Z	2026-02-02T23:25:51.8652754Z	\N	\N	\N	\N
ac2537d2-277b-42ae-8739-a2f87fbe47e6	8bbb6c58-b963-4f67-b001-c8fa41582afd	login	User	8bbb6c58-b963-4f67-b001-c8fa41582afd	\N	{"Email":"adm_ca@telecuidar.com","LoginTime":"2026-02-03T01:06:38.4990617Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 Edg/144.0.0.0	2026-02-03T01:06:38.5080072Z	2026-02-03T01:06:38.5080075Z	\N	\N	\N	\N
249c7af0-c557-4cf4-801c-1ffdcb558caa	8bbb6c58-b963-4f67-b001-c8fa41582afd	login	User	8bbb6c58-b963-4f67-b001-c8fa41582afd	\N	{"Email":"adm_ca@telecuidar.com","LoginTime":"2026-02-03T01:16:09.6648388Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 Edg/144.0.0.0	2026-02-03T01:16:09.6659203Z	2026-02-03T01:16:09.6659205Z	\N	\N	\N	\N
3484ea8d-cefb-4520-b784-d0a753ba3336	d61f6fb1-d2cd-4350-b242-003ac3a4464f	login	User	d61f6fb1-d2cd-4350-b242-003ac3a4464f	\N	{"Email":"enf_do@telecuidar.com","LoginTime":"2026-02-03T01:36:13.9336516Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T01:36:13.9337555Z	2026-02-03T01:36:13.9337556Z	\N	\N	\N	\N
45bba640-a9c5-436b-a017-7df33445c901	8bbb6c58-b963-4f67-b001-c8fa41582afd	login	User	8bbb6c58-b963-4f67-b001-c8fa41582afd	\N	{"Email":"adm_ca@telecuidar.com","LoginTime":"2026-02-03T02:01:14.2534945Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 Edg/144.0.0.0	2026-02-03T02:01:14.2619782Z	2026-02-03T02:01:14.2619784Z	\N	\N	\N	\N
d7d4a936-6d61-40b8-8fae-63cf84131975	8bbb6c58-b963-4f67-b001-c8fa41582afd	delete	User	d6632c0a-fcf3-4a19-a812-2b68ff4416a3	{"Email":"med_dc@telecuidar.com","Name":"Daniel","LastName":"Carrara","Role":"PROFESSIONAL"}	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 Edg/144.0.0.0	2026-02-03T02:01:23.9767542Z	2026-02-03T02:01:23.9767542Z	\N	\N	\N	\N
34d52ea8-260f-46a1-b612-22635d1cbc3a	8bbb6c58-b963-4f67-b001-c8fa41582afd	delete	User	80a84ea3-f080-46ef-8aa9-83f778c556f1	{"Email":"med_do@telecuidar.com","Name":"Daniela","LastName":"Ochoa","Role":"PROFESSIONAL"}	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 Edg/144.0.0.0	2026-02-03T02:01:31.4990904Z	2026-02-03T02:01:31.4990906Z	\N	\N	\N	\N
e1b3ee0e-c75e-426b-8f30-85dc38ad94f0	8bbb6c58-b963-4f67-b001-c8fa41582afd	delete	User	747a3c9b-f2ac-4508-aa2c-74114e8c4ee5	{"Email":"med_ca@telecuidar.com","Name":"Cl\\u00E1udio","LastName":"Amantino","Role":"PROFESSIONAL"}	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 Edg/144.0.0.0	2026-02-03T02:01:40.1318380Z	2026-02-03T02:01:40.1318381Z	\N	\N	\N	\N
4a78c769-cab7-4344-97a4-d0811df07ccf	8bbb6c58-b963-4f67-b001-c8fa41582afd	delete	User	454ac25e-cfd7-40c7-9d2e-4bb73847544c	{"Email":"pac_aj@telecuidar.com","Name":"Ant\\u00F4nio","LastName":"Jorge","Role":"PATIENT"}	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 Edg/144.0.0.0	2026-02-03T02:01:49.9185149Z	2026-02-03T02:01:49.9185150Z	\N	\N	\N	\N
c58393f6-5a75-45b8-84d3-fd1274a20bfa	8bbb6c58-b963-4f67-b001-c8fa41582afd	delete	User	56b3e186-118c-45ba-a49b-a61b8166c026	{"Email":"pac_gt@telecuidar.com","Name":"Geraldo","LastName":"Tadeu","Role":"PATIENT"}	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 Edg/144.0.0.0	2026-02-03T02:01:57.3101208Z	2026-02-03T02:01:57.3101209Z	\N	\N	\N	\N
d0cdc03c-4c4d-4d8a-afa0-39befd14de5f	8bbb6c58-b963-4f67-b001-c8fa41582afd	delete	Specialty	0300914f-9def-4fab-9ef0-4325f02deb17	{"Name":"Cardiologia","Description":"Especialidade m\\u00E9dica dedicada ao diagn\\u00F3stico e tratamento de doen\\u00E7as do cora\\u00E7\\u00E3o e do sistema circulat\\u00F3rio, incluindo hipertens\\u00E3o, insufici\\u00EAncia card\\u00EDaca, arritmias e doen\\u00E7as coronarianas."}	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 Edg/144.0.0.0	2026-02-03T02:02:14.2105329Z	2026-02-03T02:02:14.2105329Z	\N	\N	\N	\N
e8d14d27-f7be-46fa-b1b4-cb74aa81a8d2	f00d2c7c-cca1-4758-b64a-740042d900c5	spontaneous_demand_created	Appointment	6018ee39-59ac-44bf-b409-9875b5c17169	\N	Demanda espont├ónea criada: Daniel - Psiquiatria (Urg├¬ncia: Red)	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T02:04:42.8046201Z	2026-02-03T02:04:42.8046204Z	\N	\N	\N	\N
b5551bbd-54c8-41ce-8e8c-3393d78e2d8a	6bf6f665-96ba-4aae-8a65-cfba0624bd49	login	User	6bf6f665-96ba-4aae-8a65-cfba0624bd49	\N	{"Email":"pac_dc@telecuidar.com","LoginTime":"2026-02-03T02:16:36.6044578Z"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T02:16:36.6045378Z	2026-02-03T02:16:36.6045378Z	\N	\N	\N	\N
7f6f3fd4-bc82-485c-bc5f-ee60365c8d0f	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	login	User	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	\N	{"Email":"med_aj@telecuidar.com","LoginTime":"2026-02-03T02:21:06.4668475Z"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T02:21:06.4669284Z	2026-02-03T02:21:06.4669284Z	\N	\N	\N	\N
c72b26fc-b885-4e1e-8b95-c2c99cafccf8	8bbb6c58-b963-4f67-b001-c8fa41582afd	login	User	8bbb6c58-b963-4f67-b001-c8fa41582afd	\N	{"Email":"adm_ca@telecuidar.com","LoginTime":"2026-02-03T02:28:47.7935162Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 Edg/144.0.0.0	2026-02-03T02:28:47.8036170Z	2026-02-03T02:28:47.8036175Z	\N	\N	\N	\N
bfff5b0a-9c30-4ed8-b22b-6b2ef1043f85	8bbb6c58-b963-4f67-b001-c8fa41582afd	delete	User	49f0cc4c-0116-45bc-a5cb-4991a0f4b872	{"Email":"paciente@paciente.com","Name":"paciente","LastName":"teste","Role":"PATIENT"}	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 Edg/144.0.0.0	2026-02-03T02:28:59.3445241Z	2026-02-03T02:28:59.3445243Z	\N	\N	\N	\N
ef305725-5722-4d07-bae5-0cc249d45ec8	8bbb6c58-b963-4f67-b001-c8fa41582afd	delete	User	922e0ee4-20e5-4469-9a12-e363f12f8a48	{"Email":"assis@assis.com","Name":"Assis","LastName":"Assistente","Role":"ASSISTANT"}	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 Edg/144.0.0.0	2026-02-03T02:29:09.3057399Z	2026-02-03T02:29:09.3057400Z	\N	\N	\N	\N
ad862904-2f8d-4f80-903a-18a7c369a443	8bbb6c58-b963-4f67-b001-c8fa41582afd	delete	User	3210fa34-8242-4916-a864-7f8fa0eb2265	{"Email":"pac@pac.com","Name":"Paciente","LastName":"De Teste","Role":"PATIENT"}	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 Edg/144.0.0.0	2026-02-03T02:29:14.9725133Z	2026-02-03T02:29:14.9725134Z	\N	\N	\N	\N
dced14d3-3cd1-471f-be91-9f03db8f565f	8bbb6c58-b963-4f67-b001-c8fa41582afd	delete	User	aaaa5050-dfc2-42d9-a849-ab9a8b354cac	{"Email":"med@med.com","Name":"M\\u00E9dico","LastName":"Teste","Role":"PROFESSIONAL"}	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 Edg/144.0.0.0	2026-02-03T02:29:19.0794377Z	2026-02-03T02:29:19.0794390Z	\N	\N	\N	\N
3124108d-72d7-4ff5-87e9-7cfaffaafb39	d61f6fb1-d2cd-4350-b242-003ac3a4464f	start_consultation	Appointment	91bce788-2b3b-4a2b-bb83-62eabc7b2727	{"Status":3}	{"Status":"InProgress","ConsultationStartedAt":"2026-02-03T10:47:47.472158Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T10:47:47.4820484Z	2026-02-03T10:47:47.4820485Z	\N	\N	\N	\N
efae15c3-1ac6-41d6-abad-fb9e5f825577	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	91bce788-2b3b-4a2b-bb83-62eabc7b2727	\N	{"RoomName":"91bce7882b3b4a2bbb8362eabc7b2727","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T10:47:47.6055740Z	2026-02-03T10:47:47.6055740Z	\N	\N	\N	\N
58f47c64-4499-4d4e-8b28-7e6771995fdc	d61f6fb1-d2cd-4350-b242-003ac3a4464f	login	User	d61f6fb1-d2cd-4350-b242-003ac3a4464f	\N	{"Email":"enf_do@telecuidar.com","LoginTime":"2026-02-03T11:57:25.87782Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T11:57:25.8779047Z	2026-02-03T11:57:25.8779048Z	\N	\N	\N	\N
d28efba8-28d6-44fd-b6a2-dd02f2e72c98	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	jitsi_access	Appointment	91bce788-2b3b-4a2b-bb83-62eabc7b2727	\N	{"RoomName":"91bce7882b3b4a2bbb8362eabc7b2727","IsModerator":true,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T13:32:17.1776813Z	2026-02-03T13:32:17.1776814Z	\N	\N	\N	\N
2b1164ae-de35-4e4e-afb4-5eb9181fa431	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	d8567e18-665b-4421-9746-27f728456f76	\N	{"RoomName":"d8567e18665b4421974627f728456f76","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T13:52:13.1459888Z	2026-02-03T13:52:13.1459890Z	\N	\N	\N	\N
430054c1-5eb5-43d6-afa6-54df8d5f9c24	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	jitsi_access	Appointment	91bce788-2b3b-4a2b-bb83-62eabc7b2727	\N	{"RoomName":"91bce7882b3b4a2bbb8362eabc7b2727","IsModerator":true,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T13:52:13.5603475Z	2026-02-03T13:52:13.5603475Z	\N	\N	\N	\N
ac954e58-bf48-41b3-9d86-0df3542b136f	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	d8567e18-665b-4421-9746-27f728456f76	\N	{"RoomName":"d8567e18665b4421974627f728456f76","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T14:12:04.6403170Z	2026-02-03T14:12:04.6403171Z	\N	\N	\N	\N
9941fe69-bc6b-4cbe-888f-8c2d8aac9ad6	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	jitsi_access	Appointment	91bce788-2b3b-4a2b-bb83-62eabc7b2727	\N	{"RoomName":"91bce7882b3b4a2bbb8362eabc7b2727","IsModerator":true,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T14:27:41.5843298Z	2026-02-03T14:27:41.5843301Z	\N	\N	\N	\N
ac4125b7-9f97-4551-b04a-a169744f7a29	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	d8567e18-665b-4421-9746-27f728456f76	\N	{"RoomName":"d8567e18665b4421974627f728456f76","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T14:31:31.9884772Z	2026-02-03T14:31:31.9884773Z	\N	\N	\N	\N
38d15e06-ae03-4ed9-919b-6271b4677ee6	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	d8567e18-665b-4421-9746-27f728456f76	\N	{"RoomName":"d8567e18665b4421974627f728456f76","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T14:36:38.2077100Z	2026-02-03T14:36:38.2077101Z	\N	\N	\N	\N
1988faab-c02a-44e7-8333-cab896536720	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	jitsi_access	Appointment	91bce788-2b3b-4a2b-bb83-62eabc7b2727	\N	{"RoomName":"91bce7882b3b4a2bbb8362eabc7b2727","IsModerator":true,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T14:37:07.3522193Z	2026-02-03T14:37:07.3522193Z	\N	\N	\N	\N
803a012d-acdb-41e9-bab4-2977348221c8	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	jitsi_access	Appointment	91bce788-2b3b-4a2b-bb83-62eabc7b2727	\N	{"RoomName":"91bce7882b3b4a2bbb8362eabc7b2727","IsModerator":true,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T14:43:26.4688930Z	2026-02-03T14:43:26.4688931Z	\N	\N	\N	\N
797ef62b-1364-4562-a6d5-fbcc3f6ba6e1	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	d8567e18-665b-4421-9746-27f728456f76	\N	{"RoomName":"d8567e18665b4421974627f728456f76","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T14:43:26.8752405Z	2026-02-03T14:43:26.8752406Z	\N	\N	\N	\N
9584f05c-62e9-412e-809d-b2d989ffdbb8	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	d8567e18-665b-4421-9746-27f728456f76	\N	{"RoomName":"d8567e18665b4421974627f728456f76","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T14:46:16.4619354Z	2026-02-03T14:46:16.4619356Z	\N	\N	\N	\N
952a1c2b-3445-459e-855d-f48e146cc95d	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	d8567e18-665b-4421-9746-27f728456f76	\N	{"RoomName":"d8567e18665b4421974627f728456f76","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T14:46:22.3943178Z	2026-02-03T14:46:22.3943179Z	\N	\N	\N	\N
fc1bc044-2209-415e-b1fa-2cd5b7988310	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	jitsi_access	Appointment	91bce788-2b3b-4a2b-bb83-62eabc7b2727	\N	{"RoomName":"91bce7882b3b4a2bbb8362eabc7b2727","IsModerator":true,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T14:46:53.2796648Z	2026-02-03T14:46:53.2796648Z	\N	\N	\N	\N
60ffd55b-ecef-482b-af03-bc336c5c7c61	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	d8567e18-665b-4421-9746-27f728456f76	\N	{"RoomName":"d8567e18665b4421974627f728456f76","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T15:03:05.4200141Z	2026-02-03T15:03:05.4200146Z	\N	\N	\N	\N
0d51b5ed-10f3-4c43-a87c-eddd3778b112	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	d8567e18-665b-4421-9746-27f728456f76	\N	{"RoomName":"d8567e18665b4421974627f728456f76","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T15:07:28.8564918Z	2026-02-03T15:07:28.8564919Z	\N	\N	\N	\N
eebdc192-55a3-4467-8916-3bf03f769772	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	d8567e18-665b-4421-9746-27f728456f76	\N	{"RoomName":"d8567e18665b4421974627f728456f76","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T15:09:00.8271570Z	2026-02-03T15:09:00.8271571Z	\N	\N	\N	\N
0c6df8ad-1366-4286-ad0d-74ce7da0e6d1	d61f6fb1-d2cd-4350-b242-003ac3a4464f	login	User	d61f6fb1-d2cd-4350-b242-003ac3a4464f	\N	{"Email":"enf_do@telecuidar.com","LoginTime":"2026-02-03T15:10:47.3769183Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T15:10:47.3778715Z	2026-02-03T15:10:47.3778716Z	\N	\N	\N	\N
bfd19b7b-36ba-415b-8bb1-a97c39858a41	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	d8567e18-665b-4421-9746-27f728456f76	\N	{"RoomName":"d8567e18665b4421974627f728456f76","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T15:10:53.6202914Z	2026-02-03T15:10:53.6202915Z	\N	\N	\N	\N
1d0af77f-6822-4b39-9dfe-7f49daa943d9	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	d8567e18-665b-4421-9746-27f728456f76	\N	{"RoomName":"d8567e18665b4421974627f728456f76","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T16:04:41.4347818Z	2026-02-03T16:04:41.4347819Z	\N	\N	\N	\N
39e4489d-7f26-479c-9f99-c086f812de15	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	d8567e18-665b-4421-9746-27f728456f76	\N	{"RoomName":"d8567e18665b4421974627f728456f76","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T16:06:29.9172690Z	2026-02-03T16:06:29.9172690Z	\N	\N	\N	\N
e054f71a-8b83-4e3c-8965-e24bb599f1ce	d61f6fb1-d2cd-4350-b242-003ac3a4464f	login	User	d61f6fb1-d2cd-4350-b242-003ac3a4464f	\N	{"Email":"enf_do@telecuidar.com","LoginTime":"2026-02-03T16:24:14.340138Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T16:24:14.3422632Z	2026-02-03T16:24:14.3422633Z	\N	\N	\N	\N
797b37a6-ea57-4628-a135-2bbb610f743f	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	d8567e18-665b-4421-9746-27f728456f76	\N	{"RoomName":"d8567e18665b4421974627f728456f76","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T16:24:19.6640927Z	2026-02-03T16:24:19.6640928Z	\N	\N	\N	\N
e98ea81f-a763-4105-94e5-09677d70542d	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	login	User	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	\N	{"Email":"med_aj@telecuidar.com","LoginTime":"2026-02-03T16:24:56.5444436Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T16:24:56.5445522Z	2026-02-03T16:24:56.5445523Z	\N	\N	\N	\N
23c345b6-8c64-46f1-8156-5763640c0460	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	jitsi_access	Appointment	91bce788-2b3b-4a2b-bb83-62eabc7b2727	\N	{"RoomName":"91bce7882b3b4a2bbb8362eabc7b2727","IsModerator":true,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T16:25:00.9230455Z	2026-02-03T16:25:00.9230456Z	\N	\N	\N	\N
8eaec663-8d76-4f18-816f-c88ae5463ac0	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	d8567e18-665b-4421-9746-27f728456f76	\N	{"RoomName":"d8567e18665b4421974627f728456f76","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T16:40:15.0766378Z	2026-02-03T16:40:15.0766383Z	\N	\N	\N	\N
ca016d9f-7bb4-49b5-8f3a-5b54723c05ee	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	d8567e18-665b-4421-9746-27f728456f76	\N	{"RoomName":"d8567e18665b4421974627f728456f76","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T16:50:24.3169801Z	2026-02-03T16:50:24.3169804Z	\N	\N	\N	\N
99d55772-3606-468b-8411-2f52f4057385	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	jitsi_access	Appointment	91bce788-2b3b-4a2b-bb83-62eabc7b2727	\N	{"RoomName":"91bce7882b3b4a2bbb8362eabc7b2727","IsModerator":true,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T16:50:42.5201439Z	2026-02-03T16:50:42.5201440Z	\N	\N	\N	\N
63da163f-3276-4509-98e6-6d4dbb91d5c3	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	d8567e18-665b-4421-9746-27f728456f76	\N	{"RoomName":"d8567e18665b4421974627f728456f76","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T16:51:18.3616841Z	2026-02-03T16:51:18.3616841Z	\N	\N	\N	\N
d2e4e8a9-3d11-4ac8-859b-701c69fd759a	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	login	User	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	\N	{"Email":"med_aj@telecuidar.com","LoginTime":"2026-02-03T17:54:07.9044785Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T17:54:07.9062724Z	2026-02-03T17:54:07.9062725Z	\N	\N	\N	\N
e1642449-6e05-405d-8850-415f88aec75b	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	jitsi_access	Appointment	91bce788-2b3b-4a2b-bb83-62eabc7b2727	\N	{"RoomName":"91bce7882b3b4a2bbb8362eabc7b2727","IsModerator":true,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T17:54:11.3564712Z	2026-02-03T17:54:11.3564712Z	\N	\N	\N	\N
153f4581-3055-401b-b2d2-045e34e0bbd7	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	VIEW_CLINICAL_TIMELINE	Patient	0b3b0ee6-1eec-4598-9d30-09442a923ae1	\N	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T17:54:37.2413351Z	2026-02-03T17:54:37.2413352Z	Visualiza├º├úo durante teleconsulta	PRONTUARIO	90000000018	0b3b0ee6-1eec-4598-9d30-09442a923ae1
6fe5451b-4897-48e3-93c7-9f3c13046767	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	login	User	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	\N	{"Email":"med_aj@telecuidar.com","LoginTime":"2026-02-03T17:55:11.3265303Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T17:55:11.3266113Z	2026-02-03T17:55:11.3266114Z	\N	\N	\N	\N
232ce105-e94a-43ad-97b6-e4c0bd7de6b3	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	jitsi_access	Appointment	91bce788-2b3b-4a2b-bb83-62eabc7b2727	\N	{"RoomName":"91bce7882b3b4a2bbb8362eabc7b2727","IsModerator":true,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T17:55:14.7621289Z	2026-02-03T17:55:14.7621289Z	\N	\N	\N	\N
ee862fa2-0422-44ec-8ef7-b65d320ff487	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	login	User	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	\N	{"Email":"med_aj@telecuidar.com","LoginTime":"2026-02-03T17:55:40.0960539Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T17:55:40.0970021Z	2026-02-03T17:55:40.0970022Z	\N	\N	\N	\N
34f95201-826b-46c6-92dc-f3f8b3842468	d61f6fb1-d2cd-4350-b242-003ac3a4464f	login	User	d61f6fb1-d2cd-4350-b242-003ac3a4464f	\N	{"Email":"enf_do@telecuidar.com","LoginTime":"2026-02-03T17:56:05.4937198Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T17:56:05.4938928Z	2026-02-03T17:56:05.4938929Z	\N	\N	\N	\N
4e535aa4-b043-43fe-86e6-988b2f2534ea	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	d8567e18-665b-4421-9746-27f728456f76	\N	{"RoomName":"d8567e18665b4421974627f728456f76","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T17:56:10.4952971Z	2026-02-03T17:56:10.4952971Z	\N	\N	\N	\N
b1713c4e-4bf2-407a-be32-b0a791532055	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	jitsi_access	Appointment	91bce788-2b3b-4a2b-bb83-62eabc7b2727	\N	{"RoomName":"91bce7882b3b4a2bbb8362eabc7b2727","IsModerator":true,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T18:45:19.4944982Z	2026-02-03T18:45:19.4944985Z	\N	\N	\N	\N
92948b28-ad71-4bee-8252-f540f39308fd	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	jitsi_access	Appointment	91bce788-2b3b-4a2b-bb83-62eabc7b2727	\N	{"RoomName":"91bce7882b3b4a2bbb8362eabc7b2727","IsModerator":true,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T18:45:21.1979779Z	2026-02-03T18:45:21.1979791Z	\N	\N	\N	\N
27fe54ec-bc81-4dfc-b78d-ed8d1534ed1c	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	login	User	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	\N	{"Email":"med_aj@telecuidar.com","LoginTime":"2026-02-03T18:59:24.5587046Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T18:59:24.5621466Z	2026-02-03T18:59:24.5621467Z	\N	\N	\N	\N
0454ff28-4aca-4577-9794-df69ea0056ea	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	jitsi_access	Appointment	91bce788-2b3b-4a2b-bb83-62eabc7b2727	\N	{"RoomName":"91bce7882b3b4a2bbb8362eabc7b2727","IsModerator":true,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T18:59:27.6423828Z	2026-02-03T18:59:27.6423829Z	\N	\N	\N	\N
14be100a-5c29-4e05-b4b9-29b09da80438	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	login	User	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	\N	{"Email":"med_aj@telecuidar.com","LoginTime":"2026-02-03T19:26:52.8751671Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T19:26:52.8764187Z	2026-02-03T19:26:52.8764188Z	\N	\N	\N	\N
0fbc1628-500f-48cd-99d7-76ce7e67286d	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	login	User	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	\N	{"Email":"med_aj@telecuidar.com","LoginTime":"2026-02-03T19:27:39.6430822Z"}	192.168.18.161	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T19:27:39.6439329Z	2026-02-03T19:27:39.6439331Z	\N	\N	\N	\N
91977d42-61f8-4c3d-973a-67ade76c8604	f00d2c7c-cca1-4758-b64a-740042d900c5	login	User	f00d2c7c-cca1-4758-b64a-740042d900c5	\N	{"Email":"rec_ma@telecuidar.com","LoginTime":"2026-02-03T19:27:53.3296896Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T19:27:53.3297634Z	2026-02-03T19:27:53.3297634Z	\N	\N	\N	\N
75253861-7da1-409f-a16d-a78a75ca68e1	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	jitsi_access	Appointment	91bce788-2b3b-4a2b-bb83-62eabc7b2727	\N	{"RoomName":"91bce7882b3b4a2bbb8362eabc7b2727","IsModerator":true,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T19:29:15.1682075Z	2026-02-03T19:29:15.1682076Z	\N	\N	\N	\N
f2094f37-8c63-4fff-803d-1debaa7870a7	d61f6fb1-d2cd-4350-b242-003ac3a4464f	login	User	d61f6fb1-d2cd-4350-b242-003ac3a4464f	\N	{"Email":"enf_do@telecuidar.com","LoginTime":"2026-02-03T19:29:35.8636723Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T19:29:35.8637444Z	2026-02-03T19:29:35.8637444Z	\N	\N	\N	\N
d73c6fc8-b0ff-4355-a9ce-98e71dc99b28	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	d8567e18-665b-4421-9746-27f728456f76	\N	{"RoomName":"d8567e18665b4421974627f728456f76","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T19:29:43.4260142Z	2026-02-03T19:29:43.4260148Z	\N	\N	\N	\N
9b5f59c7-07a1-4463-bc4b-c13618dc1717	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	d8567e18-665b-4421-9746-27f728456f76	\N	{"RoomName":"d8567e18665b4421974627f728456f76","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T19:38:08.4925812Z	2026-02-03T19:38:08.4925815Z	\N	\N	\N	\N
04eb67e4-c5f1-4696-90a7-1cd309d7a1e7	f00d2c7c-cca1-4758-b64a-740042d900c5	spontaneous_demand_created	Appointment	81986d3d-a66e-4cff-8205-c8f79985d00c	\N	Demanda espont├ónea criada: Daniel - Psiquiatria (Urg├¬ncia: Red)	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T19:39:59.7814077Z	2026-02-03T19:39:59.7814081Z	\N	\N	\N	\N
265d1b1a-1d08-452d-b05e-90ee64bf4552	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	d8567e18-665b-4421-9746-27f728456f76	\N	{"RoomName":"d8567e18665b4421974627f728456f76","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T19:40:19.4493218Z	2026-02-03T19:40:19.4493219Z	\N	\N	\N	\N
8182b12e-c2b9-4a01-b61f-e8c4e5104f32	f00d2c7c-cca1-4758-b64a-740042d900c5	login	User	f00d2c7c-cca1-4758-b64a-740042d900c5	\N	{"Email":"rec_ma@telecuidar.com","LoginTime":"2026-02-03T22:09:33.5184089Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T22:09:33.5204602Z	2026-02-03T22:09:33.5204604Z	\N	\N	\N	\N
5c5ef1a4-2bb9-4672-a5ee-6718d1e575b5	f00d2c7c-cca1-4758-b64a-740042d900c5	spontaneous_demand_created	Appointment	90b0c818-39c3-4b6b-9e58-02e71a85654b	\N	Demanda espont├ónea criada: Daniel - Psiquiatria (Urg├¬ncia: Red)	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T22:10:00.6100534Z	2026-02-03T22:10:00.6100535Z	\N	\N	\N	\N
6ce63132-1b0a-43f9-918c-ec53623932eb	d61f6fb1-d2cd-4350-b242-003ac3a4464f	login	User	d61f6fb1-d2cd-4350-b242-003ac3a4464f	\N	{"Email":"enf_do@telecuidar.com","LoginTime":"2026-02-03T22:10:54.3717203Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T22:10:54.3718057Z	2026-02-03T22:10:54.3718058Z	\N	\N	\N	\N
9ec813ea-34bb-40ff-8d00-2a1afc835a9d	d61f6fb1-d2cd-4350-b242-003ac3a4464f	login	User	d61f6fb1-d2cd-4350-b242-003ac3a4464f	\N	{"Email":"enf_do@telecuidar.com","LoginTime":"2026-02-03T22:11:12.4594256Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T22:11:12.4595724Z	2026-02-03T22:11:12.4595725Z	\N	\N	\N	\N
75737413-0c97-4777-97dd-7a8d6138e9d8	d61f6fb1-d2cd-4350-b242-003ac3a4464f	login	User	d61f6fb1-d2cd-4350-b242-003ac3a4464f	\N	{"Email":"enf_do@telecuidar.com","LoginTime":"2026-02-03T22:15:11.4463335Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T22:15:11.4464169Z	2026-02-03T22:15:11.4464169Z	\N	\N	\N	\N
e5ce78b0-13c3-47ef-84a1-6731aa1e2fee	d61f6fb1-d2cd-4350-b242-003ac3a4464f	login	User	d61f6fb1-d2cd-4350-b242-003ac3a4464f	\N	{"Email":"enf_do@telecuidar.com","LoginTime":"2026-02-03T22:23:50.9853997Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T22:23:50.9867902Z	2026-02-03T22:23:50.9867903Z	\N	\N	\N	\N
ad29098f-e398-4ebf-87b3-06c4cece7b6c	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	login	User	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	\N	{"Email":"med_aj@telecuidar.com","LoginTime":"2026-02-03T22:32:01.0432627Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T22:32:01.0434078Z	2026-02-03T22:32:01.0434080Z	\N	\N	\N	\N
f648b46f-ba90-4b8f-aca3-87c47b255c12	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	jitsi_access	Appointment	91bce788-2b3b-4a2b-bb83-62eabc7b2727	\N	{"RoomName":"91bce7882b3b4a2bbb8362eabc7b2727","IsModerator":true,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T22:32:37.7011950Z	2026-02-03T22:32:37.7011951Z	\N	\N	\N	\N
548083e0-8c87-4b3c-b1b0-36b22a7f3e8a	d61f6fb1-d2cd-4350-b242-003ac3a4464f	login	User	d61f6fb1-d2cd-4350-b242-003ac3a4464f	\N	{"Email":"enf_do@telecuidar.com","LoginTime":"2026-02-03T22:40:35.3561115Z"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T22:40:35.3562448Z	2026-02-03T22:40:35.3562449Z	\N	\N	\N	\N
2199fe31-4bcd-47d6-a2b0-2d55bf052387	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	jitsi_access	Appointment	91bce788-2b3b-4a2b-bb83-62eabc7b2727	\N	{"RoomName":"91bce7882b3b4a2bbb8362eabc7b2727","IsModerator":true,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T22:52:33.9445570Z	2026-02-03T22:52:33.9445573Z	\N	\N	\N	\N
14454160-b40d-4774-a1d7-cba5bd41d51f	d61f6fb1-d2cd-4350-b242-003ac3a4464f	start_consultation	Appointment	b436b904-02c5-4e0b-840e-04a7fc302994	{"Status":3}	{"Status":"InProgress","ConsultationStartedAt":"2026-02-03T22:55:31.8544476Z"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T22:55:31.9239529Z	2026-02-03T22:55:31.9239531Z	\N	\N	\N	\N
2539ff13-27d1-4bc5-bfaa-beeb09d0838f	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	b436b904-02c5-4e0b-840e-04a7fc302994	\N	{"RoomName":"b436b90402c54e0b840e04a7fc302994","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T22:55:32.1655310Z	2026-02-03T22:55:32.1655310Z	\N	\N	\N	\N
014ef6f4-0c74-45dc-8d97-e68fd83b1970	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	login	User	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	\N	{"Email":"med_aj@telecuidar.com","LoginTime":"2026-02-03T23:13:19.9772939Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T23:13:19.9791182Z	2026-02-03T23:13:19.9791183Z	\N	\N	\N	\N
50ca298e-abe6-4e56-90af-2b64e181a2d8	d61f6fb1-d2cd-4350-b242-003ac3a4464f	start_consultation	Appointment	81986d3d-a66e-4cff-8205-c8f79985d00c	{"Status":3}	{"Status":"InProgress","ConsultationStartedAt":"2026-02-03T23:13:27.2413521Z"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T23:13:27.2493131Z	2026-02-03T23:13:27.2493132Z	\N	\N	\N	\N
b2425e10-ac56-4b48-af98-798177018b47	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	81986d3d-a66e-4cff-8205-c8f79985d00c	\N	{"RoomName":"81986d3da66e4cff8205c8f79985d00c","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T23:13:27.4056585Z	2026-02-03T23:13:27.4056585Z	\N	\N	\N	\N
5e30f427-b763-40b6-a3eb-951aa50296db	d61f6fb1-d2cd-4350-b242-003ac3a4464f	start_consultation	Appointment	90b0c818-39c3-4b6b-9e58-02e71a85654b	{"Status":3}	{"Status":"InProgress","ConsultationStartedAt":"2026-02-03T23:14:16.0861247Z"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T23:14:16.0942736Z	2026-02-03T23:14:16.0942738Z	\N	\N	\N	\N
aa5ca89a-0a80-4ef4-8a06-2cba8a919fde	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	90b0c818-39c3-4b6b-9e58-02e71a85654b	\N	{"RoomName":"90b0c81839c34b6b9e5802e71a85654b","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T23:14:16.2365943Z	2026-02-03T23:14:16.2365943Z	\N	\N	\N	\N
50b1559b-9706-4e01-ba75-e9075042f130	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	login	User	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	\N	{"Email":"med_aj@telecuidar.com","LoginTime":"2026-02-03T23:29:22.2374711Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T23:29:22.2457177Z	2026-02-03T23:29:22.2457179Z	\N	\N	\N	\N
5181fbdd-6561-406d-be1c-66cd15a712ba	f00d2c7c-cca1-4758-b64a-740042d900c5	login	User	f00d2c7c-cca1-4758-b64a-740042d900c5	\N	{"Email":"rec_ma@telecuidar.com","LoginTime":"2026-02-03T23:29:47.0561734Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T23:29:47.0570189Z	2026-02-03T23:29:47.0570190Z	\N	\N	\N	\N
dbfbb83f-5145-4ac6-bd55-93382031895f	f00d2c7c-cca1-4758-b64a-740042d900c5	spontaneous_demand_created	Appointment	10cc823e-714b-4830-838f-3ec59c7b2f19	\N	Demanda espont├ónea criada: Daniela - Psiquiatria (Urg├¬ncia: Red)	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T23:30:06.1403425Z	2026-02-03T23:30:06.1403428Z	\N	\N	\N	\N
700a9a71-2a9e-4420-8f14-a6d6dda461bf	d61f6fb1-d2cd-4350-b242-003ac3a4464f	start_consultation	Appointment	10cc823e-714b-4830-838f-3ec59c7b2f19	{"Status":3}	{"Status":"InProgress","ConsultationStartedAt":"2026-02-03T23:30:28.9788464Z"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T23:30:28.9965081Z	2026-02-03T23:30:28.9965082Z	\N	\N	\N	\N
4b706aa6-ef89-43c2-9dda-d5b3fefc11ae	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	10cc823e-714b-4830-838f-3ec59c7b2f19	\N	{"RoomName":"10cc823e714b4830838f3ec59c7b2f19","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T23:30:29.2902003Z	2026-02-03T23:30:29.2902005Z	\N	\N	\N	\N
4a0822a9-44e4-4735-9015-bc0c9d2937ab	f00d2c7c-cca1-4758-b64a-740042d900c5	spontaneous_demand_created	Appointment	1f90dce8-e7cb-4cf3-9b3b-f36f64b93d11	\N	Demanda espont├ónea criada: Daniel - Psiquiatria (Urg├¬ncia: Yellow)	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T23:32:30.5789930Z	2026-02-03T23:32:30.5789931Z	\N	\N	\N	\N
90e4f48d-3655-4cbd-a2b9-54278501051a	d61f6fb1-d2cd-4350-b242-003ac3a4464f	start_consultation	Appointment	1f90dce8-e7cb-4cf3-9b3b-f36f64b93d11	{"Status":3}	{"Status":"InProgress","ConsultationStartedAt":"2026-02-03T23:32:52.287296Z"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T23:32:52.2937892Z	2026-02-03T23:32:52.2937893Z	\N	\N	\N	\N
a362c09a-19ad-470b-ae00-a6e88b620a4e	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	1f90dce8-e7cb-4cf3-9b3b-f36f64b93d11	\N	{"RoomName":"1f90dce8e7cb4cf39b3bf36f64b93d11","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T23:32:52.5553709Z	2026-02-03T23:32:52.5553710Z	\N	\N	\N	\N
2d2e85e2-9519-4fa6-ba0d-6df6a190b928	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	login	User	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	\N	{"Email":"med_aj@telecuidar.com","LoginTime":"2026-02-03T23:42:49.3462136Z"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T23:42:49.3463228Z	2026-02-03T23:42:49.3463228Z	\N	\N	\N	\N
f4031eb2-3d57-49bb-8a51-06ad57d5baf0	f00d2c7c-cca1-4758-b64a-740042d900c5	spontaneous_demand_created	Appointment	6dab8d5e-c8f7-4c0a-b4cc-2e292ae3d662	\N	Demanda espont├ónea criada: Daniela - Psiquiatria (Urg├¬ncia: Red)	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T23:47:52.4363108Z	2026-02-03T23:47:52.4363112Z	\N	\N	\N	\N
59c6f555-ed2f-4c2d-85cc-b80b4e02bf02	d61f6fb1-d2cd-4350-b242-003ac3a4464f	login	User	d61f6fb1-d2cd-4350-b242-003ac3a4464f	\N	{"Email":"enf_do@telecuidar.com","LoginTime":"2026-02-03T23:48:26.3825819Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T23:48:26.3866831Z	2026-02-03T23:48:26.3866833Z	\N	\N	\N	\N
6a831ad9-9495-40f9-8542-fbeea93f9eba	d61f6fb1-d2cd-4350-b242-003ac3a4464f	start_consultation	Appointment	6dab8d5e-c8f7-4c0a-b4cc-2e292ae3d662	{"Status":3}	{"Status":"InProgress","ConsultationStartedAt":"2026-02-03T23:48:46.381774Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T23:48:46.4062901Z	2026-02-03T23:48:46.4062902Z	\N	\N	\N	\N
faa5f80f-65fb-441b-8928-4028df7cf12c	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	6dab8d5e-c8f7-4c0a-b4cc-2e292ae3d662	\N	{"RoomName":"6dab8d5ec8f74c0ab4cc2e292ae3d662","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-03T23:48:46.5809321Z	2026-02-03T23:48:46.5809330Z	\N	\N	\N	\N
4e4a37a0-9531-400f-bbd0-31b53dac543d	d61f6fb1-d2cd-4350-b242-003ac3a4464f	login	User	d61f6fb1-d2cd-4350-b242-003ac3a4464f	\N	{"Email":"enf_do@telecuidar.com","LoginTime":"2026-02-04T05:38:14.9320676Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T05:38:14.9610231Z	2026-02-04T05:38:14.9610234Z	\N	\N	\N	\N
8526e70c-c873-4451-9e35-8f1b2cef772c	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	login	User	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	\N	{"Email":"med_aj@telecuidar.com","LoginTime":"2026-02-04T05:39:20.5183189Z"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T05:39:20.5190577Z	2026-02-04T05:39:20.5190577Z	\N	\N	\N	\N
09eeb80c-3b89-49a9-9897-f031c1e0cffc	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	6dab8d5e-c8f7-4c0a-b4cc-2e292ae3d662	\N	{"RoomName":"6dab8d5ec8f74c0ab4cc2e292ae3d662","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T05:43:21.5745748Z	2026-02-04T05:43:21.5745749Z	\N	\N	\N	\N
9402b9a1-9423-4a3e-9cff-48600499e462	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	jitsi_access	Appointment	d8567e18-665b-4421-9746-27f728456f76	\N	{"RoomName":"d8567e18665b4421974627f728456f76","IsModerator":true,"Domain":"meet.telecuidar.com.br"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T05:43:25.2920393Z	2026-02-04T05:43:25.2920395Z	\N	\N	\N	\N
1fef6e73-1ee7-4df8-a039-842777d524d0	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	jitsi_access	Appointment	d8567e18-665b-4421-9746-27f728456f76	\N	{"RoomName":"d8567e18665b4421974627f728456f76","IsModerator":true,"Domain":"meet.telecuidar.com.br"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T05:43:35.6757097Z	2026-02-04T05:43:35.6757100Z	\N	\N	\N	\N
b600cecb-c0c5-4be0-b994-f6c7cee70e8c	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	6dab8d5e-c8f7-4c0a-b4cc-2e292ae3d662	\N	{"RoomName":"6dab8d5ec8f74c0ab4cc2e292ae3d662","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T05:44:13.4120067Z	2026-02-04T05:44:13.4120068Z	\N	\N	\N	\N
3ddec565-d1b6-4079-9a0a-409875f6be75	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	jitsi_access	Appointment	d8567e18-665b-4421-9746-27f728456f76	\N	{"RoomName":"d8567e18665b4421974627f728456f76","IsModerator":true,"Domain":"meet.telecuidar.com.br"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T05:44:24.6549679Z	2026-02-04T05:44:24.6549681Z	\N	\N	\N	\N
b58fcc81-9df8-4d88-bfe2-adcceb5f1f64	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	jitsi_access	Appointment	d8567e18-665b-4421-9746-27f728456f76	\N	{"RoomName":"d8567e18665b4421974627f728456f76","IsModerator":true,"Domain":"meet.telecuidar.com.br"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T05:44:32.3814206Z	2026-02-04T05:44:32.3814207Z	\N	\N	\N	\N
188135c3-9252-4c5c-a921-18be083309c7	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	jitsi_access	Appointment	d8567e18-665b-4421-9746-27f728456f76	\N	{"RoomName":"d8567e18665b4421974627f728456f76","IsModerator":true,"Domain":"meet.telecuidar.com.br"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T05:44:36.2904547Z	2026-02-04T05:44:36.2904549Z	\N	\N	\N	\N
0adf3647-6540-4765-b04f-da3e3b60c8d4	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	jitsi_access	Appointment	d8567e18-665b-4421-9746-27f728456f76	\N	{"RoomName":"d8567e18665b4421974627f728456f76","IsModerator":true,"Domain":"meet.telecuidar.com.br"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T05:44:41.0587222Z	2026-02-04T05:44:41.0587222Z	\N	\N	\N	\N
adddc7b9-af7e-4a9d-8015-dd0a945c3e2f	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	jitsi_access	Appointment	d8567e18-665b-4421-9746-27f728456f76	\N	{"RoomName":"d8567e18665b4421974627f728456f76","IsModerator":true,"Domain":"meet.telecuidar.com.br"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T05:44:44.4807323Z	2026-02-04T05:44:44.4807324Z	\N	\N	\N	\N
3e598577-fea3-495c-b96d-56ca3afa0766	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	jitsi_access	Appointment	d8567e18-665b-4421-9746-27f728456f76	\N	{"RoomName":"d8567e18665b4421974627f728456f76","IsModerator":true,"Domain":"meet.telecuidar.com.br"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T05:44:48.5213886Z	2026-02-04T05:44:48.5213887Z	\N	\N	\N	\N
dfa8d6d6-ce47-4eaf-b7d8-30bcb5c55411	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	jitsi_access	Appointment	d8567e18-665b-4421-9746-27f728456f76	\N	{"RoomName":"d8567e18665b4421974627f728456f76","IsModerator":true,"Domain":"meet.telecuidar.com.br"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T05:44:52.2928223Z	2026-02-04T05:44:52.2928224Z	\N	\N	\N	\N
c3a339df-ab3a-430c-be6a-da858ce173cf	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	jitsi_access	Appointment	d8567e18-665b-4421-9746-27f728456f76	\N	{"RoomName":"d8567e18665b4421974627f728456f76","IsModerator":true,"Domain":"meet.telecuidar.com.br"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T05:44:56.8585819Z	2026-02-04T05:44:56.8585819Z	\N	\N	\N	\N
896e87c4-701b-4129-9504-df40ef0d6ce8	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	jitsi_access	Appointment	d8567e18-665b-4421-9746-27f728456f76	\N	{"RoomName":"d8567e18665b4421974627f728456f76","IsModerator":true,"Domain":"meet.telecuidar.com.br"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T05:45:00.4532455Z	2026-02-04T05:45:00.4532458Z	\N	\N	\N	\N
5182f8cc-104a-430a-a483-1af083971387	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	jitsi_access	Appointment	d8567e18-665b-4421-9746-27f728456f76	\N	{"RoomName":"d8567e18665b4421974627f728456f76","IsModerator":true,"Domain":"meet.telecuidar.com.br"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T05:45:04.4020912Z	2026-02-04T05:45:04.4020915Z	\N	\N	\N	\N
bddf9f69-57d1-439b-b3b7-7f90571a8f06	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	jitsi_access	Appointment	d8567e18-665b-4421-9746-27f728456f76	\N	{"RoomName":"d8567e18665b4421974627f728456f76","IsModerator":true,"Domain":"meet.telecuidar.com.br"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T05:45:07.9237309Z	2026-02-04T05:45:07.9237310Z	\N	\N	\N	\N
7bfa3e5c-edb9-4109-874b-eba2b80b053c	d61f6fb1-d2cd-4350-b242-003ac3a4464f	login	User	d61f6fb1-d2cd-4350-b242-003ac3a4464f	\N	{"Email":"enf_do@telecuidar.com","LoginTime":"2026-02-04T07:48:12.5952019Z"}	127.0.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; pt-BR) WindowsPowerShell/5.1.26100.7462	2026-02-04T07:48:12.5953633Z	2026-02-04T07:48:12.5953634Z	\N	\N	\N	\N
47714323-33d4-4ded-88d0-f5e6caf68542	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	jitsi_access	Appointment	d8567e18-665b-4421-9746-27f728456f76	\N	{"RoomName":"d8567e18665b4421974627f728456f76","IsModerator":true,"Domain":"meet.telecuidar.com.br"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T05:45:11.8551763Z	2026-02-04T05:45:11.8551764Z	\N	\N	\N	\N
e9e56056-807d-445e-94ec-3e4b9d50b670	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	jitsi_access	Appointment	d8567e18-665b-4421-9746-27f728456f76	\N	{"RoomName":"d8567e18665b4421974627f728456f76","IsModerator":true,"Domain":"meet.telecuidar.com.br"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T05:45:15.5818775Z	2026-02-04T05:45:15.5818776Z	\N	\N	\N	\N
fa60c8ca-d4ef-448f-b5c6-16f0ed04dd66	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	jitsi_access	Appointment	d8567e18-665b-4421-9746-27f728456f76	\N	{"RoomName":"d8567e18665b4421974627f728456f76","IsModerator":true,"Domain":"meet.telecuidar.com.br"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T05:45:23.4158845Z	2026-02-04T05:45:23.4158846Z	\N	\N	\N	\N
a77ed383-38fa-484a-a556-f391c1b4b906	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	6dab8d5e-c8f7-4c0a-b4cc-2e292ae3d662	\N	{"RoomName":"6dab8d5ec8f74c0ab4cc2e292ae3d662","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T05:45:33.4558186Z	2026-02-04T05:45:33.4558187Z	\N	\N	\N	\N
406cdb5d-1b0f-4de4-8524-b6f7b9b43176	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	jitsi_access	Appointment	d8567e18-665b-4421-9746-27f728456f76	\N	{"RoomName":"d8567e18665b4421974627f728456f76","IsModerator":true,"Domain":"meet.telecuidar.com.br"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T05:45:19.8537875Z	2026-02-04T05:45:19.8537875Z	\N	\N	\N	\N
bdbdddad-7e0b-4e1d-a83a-bfd6202ab98e	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	jitsi_access	Appointment	d8567e18-665b-4421-9746-27f728456f76	\N	{"RoomName":"d8567e18665b4421974627f728456f76","IsModerator":true,"Domain":"meet.telecuidar.com.br"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T05:45:26.8876351Z	2026-02-04T05:45:26.8876351Z	\N	\N	\N	\N
6ee03889-0bda-4357-82b3-b8281eb697dd	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	login	User	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	\N	{"Email":"med_aj@telecuidar.com","LoginTime":"2026-02-04T06:02:41.4946629Z"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T06:02:41.4947521Z	2026-02-04T06:02:41.4947522Z	\N	\N	\N	\N
8ace6c1f-18bf-4f78-a912-2bf040627165	f00d2c7c-cca1-4758-b64a-740042d900c5	login	User	f00d2c7c-cca1-4758-b64a-740042d900c5	\N	{"Email":"rec_ma@telecuidar.com","LoginTime":"2026-02-04T06:03:58.1629111Z"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T06:03:58.1629843Z	2026-02-04T06:03:58.1629843Z	\N	\N	\N	\N
b14fca20-211f-4294-ae92-d3a45c2c2610	d61f6fb1-d2cd-4350-b242-003ac3a4464f	login	User	d61f6fb1-d2cd-4350-b242-003ac3a4464f	\N	{"Email":"enf_do@telecuidar.com","LoginTime":"2026-02-04T06:10:53.7431454Z"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T06:10:53.7448583Z	2026-02-04T06:10:53.7448588Z	\N	\N	\N	\N
0f8b5c09-2fee-49e8-95f5-48d1a2355947	6bf6f665-96ba-4aae-8a65-cfba0624bd49	login	User	6bf6f665-96ba-4aae-8a65-cfba0624bd49	\N	{"Email":"pac_dc@telecuidar.com","LoginTime":"2026-02-04T06:11:42.7494732Z"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T06:11:42.7495489Z	2026-02-04T06:11:42.7495490Z	\N	\N	\N	\N
6208e349-f1c7-49b8-ba50-40b2641871cd	8bbb6c58-b963-4f67-b001-c8fa41582afd	login	User	8bbb6c58-b963-4f67-b001-c8fa41582afd	\N	{"Email":"adm_ca@telecuidar.com","LoginTime":"2026-02-04T06:12:44.886573Z"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T06:12:44.8866414Z	2026-02-04T06:12:44.8866414Z	\N	\N	\N	\N
a0c10aea-407f-4785-a6ee-d677cb06f58f	8bbb6c58-b963-4f67-b001-c8fa41582afd	create	Schedule	70dfb689-ab3d-439c-9986-8470b051b464	\N	{"ProfessionalId":"a06cbf1d-2661-49ff-bbfb-0041b02dae5e","ValidityStartDate":"2026-02-04","ValidityEndDate":"2026-04-30","Status":"Active"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T06:14:15.9457407Z	2026-02-04T06:14:15.9457410Z	\N	\N	\N	\N
a15dc2c1-1064-4740-a075-62a523ae44b8	6bf6f665-96ba-4aae-8a65-cfba0624bd49	login	User	6bf6f665-96ba-4aae-8a65-cfba0624bd49	\N	{"Email":"pac_dc@telecuidar.com","LoginTime":"2026-02-04T06:14:56.2601019Z"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T06:14:56.2603831Z	2026-02-04T06:14:56.2603834Z	\N	\N	\N	\N
6f891edc-7e6f-4f35-8aa4-635461336110	6bf6f665-96ba-4aae-8a65-cfba0624bd49	create	Appointment	5ddeef0f-1ec9-473f-aaa2-b38dd51422d5	\N	{"PatientId":"6bf6f665-96ba-4aae-8a65-cfba0624bd49","ProfessionalId":"a06cbf1d-2661-49ff-bbfb-0041b02dae5e","Date":"2026-02-04T03:00:00Z","Time":"08:00","Status":"Scheduled"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T06:15:41.1355730Z	2026-02-04T06:15:41.1355745Z	\N	\N	\N	\N
c7c07911-3d99-48cc-90c2-48ad15377a03	f00d2c7c-cca1-4758-b64a-740042d900c5	login	User	f00d2c7c-cca1-4758-b64a-740042d900c5	\N	{"Email":"rec_ma@telecuidar.com","LoginTime":"2026-02-04T06:16:45.8884718Z"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T06:16:45.8886070Z	2026-02-04T06:16:45.8886071Z	\N	\N	\N	\N
d990f94b-b71e-4740-a856-1fb6ec603864	f00d2c7c-cca1-4758-b64a-740042d900c5	spontaneous_demand_created	Appointment	f8d64501-3870-4ae5-a837-ecb4770de26a	\N	Demanda espont├ónea criada: Daniel - Psiquiatria (Urg├¬ncia: Orange)	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T06:17:54.7434311Z	2026-02-04T06:17:54.7434313Z	\N	\N	\N	\N
a80450e8-f6cd-49c4-8f66-50425a5d2a48	d61f6fb1-d2cd-4350-b242-003ac3a4464f	login	User	d61f6fb1-d2cd-4350-b242-003ac3a4464f	\N	{"Email":"enf_do@telecuidar.com","LoginTime":"2026-02-04T06:18:23.5330952Z"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T06:18:23.5332483Z	2026-02-04T06:18:23.5332483Z	\N	\N	\N	\N
7a4e0fb1-8886-40a8-ba67-f42ec8fe0adc	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	login	User	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	\N	{"Email":"med_aj@telecuidar.com","LoginTime":"2026-02-04T06:20:42.212179Z"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T06:20:42.2122947Z	2026-02-04T06:20:42.2122947Z	\N	\N	\N	\N
808bb487-79ac-432f-9b39-406734d4dedb	d61f6fb1-d2cd-4350-b242-003ac3a4464f	login	User	d61f6fb1-d2cd-4350-b242-003ac3a4464f	\N	{"Email":"enf_do@telecuidar.com","LoginTime":"2026-02-04T06:22:22.8604389Z"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T06:22:22.8605347Z	2026-02-04T06:22:22.8605348Z	\N	\N	\N	\N
d39cd916-1096-4008-b7fd-15d744294321	f00d2c7c-cca1-4758-b64a-740042d900c5	login	User	f00d2c7c-cca1-4758-b64a-740042d900c5	\N	{"Email":"rec_ma@telecuidar.com","LoginTime":"2026-02-04T06:23:18.1643787Z"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T06:23:18.1644626Z	2026-02-04T06:23:18.1644627Z	\N	\N	\N	\N
ddd96743-8091-48d6-8189-a79752ca0d26	d61f6fb1-d2cd-4350-b242-003ac3a4464f	login	User	d61f6fb1-d2cd-4350-b242-003ac3a4464f	\N	{"Email":"enf_do@telecuidar.com","LoginTime":"2026-02-04T06:29:58.2969058Z"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T06:29:58.2969893Z	2026-02-04T06:29:58.2969893Z	\N	\N	\N	\N
6d41fb9a-5e55-4c37-a485-c0d2aadc32e4	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	5ddeef0f-1ec9-473f-aaa2-b38dd51422d5	\N	{"RoomName":"5ddeef0f1ec9473faaa2b38dd51422d5","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T06:30:27.1305761Z	2026-02-04T06:30:27.1305761Z	\N	\N	\N	\N
6af4e99a-47e4-4d52-84fa-c28344013500	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	5ddeef0f-1ec9-473f-aaa2-b38dd51422d5	\N	{"RoomName":"5ddeef0f1ec9473faaa2b38dd51422d5","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T06:30:35.8110774Z	2026-02-04T06:30:35.8110774Z	\N	\N	\N	\N
101d7410-ea1e-4765-a37d-2eda412221d1	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	5ddeef0f-1ec9-473f-aaa2-b38dd51422d5	\N	{"RoomName":"5ddeef0f1ec9473faaa2b38dd51422d5","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T06:30:41.1426987Z	2026-02-04T06:30:41.1426993Z	\N	\N	\N	\N
df2984e2-8713-4b16-984c-a84ce95c7543	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	5ddeef0f-1ec9-473f-aaa2-b38dd51422d5	\N	{"RoomName":"5ddeef0f1ec9473faaa2b38dd51422d5","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T06:31:14.3074410Z	2026-02-04T06:31:14.3074411Z	\N	\N	\N	\N
d80efe1d-3d03-411b-ac80-4840674c45e5	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	5ddeef0f-1ec9-473f-aaa2-b38dd51422d5	\N	{"RoomName":"5ddeef0f1ec9473faaa2b38dd51422d5","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T06:32:09.9967183Z	2026-02-04T06:32:09.9967183Z	\N	\N	\N	\N
dab7adea-a678-41b0-be37-c56a0f9aec7b	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	5ddeef0f-1ec9-473f-aaa2-b38dd51422d5	\N	{"RoomName":"5ddeef0f1ec9473faaa2b38dd51422d5","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T06:32:56.8688693Z	2026-02-04T06:32:56.8688694Z	\N	\N	\N	\N
8a2c9166-2bda-40d9-9a2f-3af609cf6d77	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	5ddeef0f-1ec9-473f-aaa2-b38dd51422d5	\N	{"RoomName":"5ddeef0f1ec9473faaa2b38dd51422d5","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T06:33:06.9950039Z	2026-02-04T06:33:06.9950040Z	\N	\N	\N	\N
0b919784-bce7-480b-be54-373d97ecb862	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	5ddeef0f-1ec9-473f-aaa2-b38dd51422d5	\N	{"RoomName":"5ddeef0f1ec9473faaa2b38dd51422d5","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T06:33:19.2064937Z	2026-02-04T06:33:19.2064938Z	\N	\N	\N	\N
5650b42a-1e16-46d5-a753-792929ee1482	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	5ddeef0f-1ec9-473f-aaa2-b38dd51422d5	\N	{"RoomName":"5ddeef0f1ec9473faaa2b38dd51422d5","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T06:33:23.3597916Z	2026-02-04T06:33:23.3597916Z	\N	\N	\N	\N
a0c5b8df-acc8-4ae4-b021-eb840232fff9	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	5ddeef0f-1ec9-473f-aaa2-b38dd51422d5	\N	{"RoomName":"5ddeef0f1ec9473faaa2b38dd51422d5","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T06:33:37.3723794Z	2026-02-04T06:33:37.3723794Z	\N	\N	\N	\N
6110a452-05cc-455d-8cff-b8813c52491f	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	5ddeef0f-1ec9-473f-aaa2-b38dd51422d5	\N	{"RoomName":"5ddeef0f1ec9473faaa2b38dd51422d5","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T06:33:56.6795255Z	2026-02-04T06:33:56.6795255Z	\N	\N	\N	\N
9edf43ec-9417-49bc-8e11-39deed98c03e	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	5ddeef0f-1ec9-473f-aaa2-b38dd51422d5	\N	{"RoomName":"5ddeef0f1ec9473faaa2b38dd51422d5","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T06:32:44.4011470Z	2026-02-04T06:32:44.4011471Z	\N	\N	\N	\N
ba080738-1686-4db1-8ed8-bff834a66add	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	5ddeef0f-1ec9-473f-aaa2-b38dd51422d5	\N	{"RoomName":"5ddeef0f1ec9473faaa2b38dd51422d5","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T06:33:33.6797197Z	2026-02-04T06:33:33.6797197Z	\N	\N	\N	\N
109ad195-455e-4f53-851f-d4b84c7decbc	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	5ddeef0f-1ec9-473f-aaa2-b38dd51422d5	\N	{"RoomName":"5ddeef0f1ec9473faaa2b38dd51422d5","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T06:33:52.9121694Z	2026-02-04T06:33:52.9121694Z	\N	\N	\N	\N
bb5979ca-8663-4495-9154-be133c1b2613	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	5ddeef0f-1ec9-473f-aaa2-b38dd51422d5	\N	{"RoomName":"5ddeef0f1ec9473faaa2b38dd51422d5","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T06:34:00.8288567Z	2026-02-04T06:34:00.8288567Z	\N	\N	\N	\N
828cf2f9-775d-432e-86c6-6ba510ab8d82	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	5ddeef0f-1ec9-473f-aaa2-b38dd51422d5	\N	{"RoomName":"5ddeef0f1ec9473faaa2b38dd51422d5","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T06:34:04.3574263Z	2026-02-04T06:34:04.3574263Z	\N	\N	\N	\N
1bb64b15-8967-495d-a730-de4d3190c389	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	5ddeef0f-1ec9-473f-aaa2-b38dd51422d5	\N	{"RoomName":"5ddeef0f1ec9473faaa2b38dd51422d5","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T06:34:08.5154844Z	2026-02-04T06:34:08.5154844Z	\N	\N	\N	\N
3ad97b6b-c48c-46ca-b531-bc3b46bca67b	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	5ddeef0f-1ec9-473f-aaa2-b38dd51422d5	\N	{"RoomName":"5ddeef0f1ec9473faaa2b38dd51422d5","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T06:34:12.2400262Z	2026-02-04T06:34:12.2400262Z	\N	\N	\N	\N
3dd8c698-b6fb-4e59-b605-fe7a3e24fc01	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	5ddeef0f-1ec9-473f-aaa2-b38dd51422d5	\N	{"RoomName":"5ddeef0f1ec9473faaa2b38dd51422d5","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T06:34:16.4446549Z	2026-02-04T06:34:16.4446549Z	\N	\N	\N	\N
96a2dee0-ce2c-4935-81a2-848a8681efd4	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	5ddeef0f-1ec9-473f-aaa2-b38dd51422d5	\N	{"RoomName":"5ddeef0f1ec9473faaa2b38dd51422d5","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T06:34:20.3009663Z	2026-02-04T06:34:20.3009664Z	\N	\N	\N	\N
899071f0-1d47-4ec2-8934-9a18d08418ca	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	5ddeef0f-1ec9-473f-aaa2-b38dd51422d5	\N	{"RoomName":"5ddeef0f1ec9473faaa2b38dd51422d5","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T06:34:42.4281573Z	2026-02-04T06:34:42.4281579Z	\N	\N	\N	\N
71f0bfc8-e20c-46e1-87a1-71ea194b2d76	d61f6fb1-d2cd-4350-b242-003ac3a4464f	login	User	d61f6fb1-d2cd-4350-b242-003ac3a4464f	\N	{"Email":"enf_do@telecuidar.com","LoginTime":"2026-02-04T06:38:51.7855701Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T06:38:51.7860205Z	2026-02-04T06:38:51.7860207Z	\N	\N	\N	\N
6b442b00-0ade-4828-9c71-39123b95229f	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	5ddeef0f-1ec9-473f-aaa2-b38dd51422d5	\N	{"RoomName":"5ddeef0f1ec9473faaa2b38dd51422d5","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T06:38:57.9449225Z	2026-02-04T06:38:57.9449230Z	\N	\N	\N	\N
1ade898a-4be4-4fa1-9763-bde0b71bd7cd	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	5ddeef0f-1ec9-473f-aaa2-b38dd51422d5	\N	{"RoomName":"5ddeef0f1ec9473faaa2b38dd51422d5","IsModerator":false,"Domain":"meet.telecuidar.com.br"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T06:39:05.7738196Z	2026-02-04T06:39:05.7738198Z	\N	\N	\N	\N
040029c3-4a97-4247-bbc5-2662361cd058	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	5ddeef0f-1ec9-473f-aaa2-b38dd51422d5	\N	{"RoomName":"5ddeef0f1ec9473faaa2b38dd51422d5","IsModerator":false,"Domain":"192.168.18.31:8443"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T06:56:34.7875755Z	2026-02-04T06:56:34.7875760Z	\N	\N	\N	\N
620734d3-5d0d-4d42-891d-eb50ec5e2887	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	5ddeef0f-1ec9-473f-aaa2-b38dd51422d5	\N	{"RoomName":"5ddeef0f1ec9473faaa2b38dd51422d5","IsModerator":false,"Domain":"192.168.18.31:8443"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T07:01:34.3104787Z	2026-02-04T07:01:34.3104790Z	\N	\N	\N	\N
19611484-1bf3-4ef4-901a-63b4f5fa076d	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	5ddeef0f-1ec9-473f-aaa2-b38dd51422d5	\N	{"RoomName":"5ddeef0f1ec9473faaa2b38dd51422d5","IsModerator":false,"Domain":"localhost:8443"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T07:02:38.2618728Z	2026-02-04T07:02:38.2618733Z	\N	\N	\N	\N
3ba5b6c2-5907-4167-8ae3-41276cb3b933	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	5ddeef0f-1ec9-473f-aaa2-b38dd51422d5	\N	{"RoomName":"5ddeef0f1ec9473faaa2b38dd51422d5","IsModerator":false,"Domain":"localhost:8443"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T07:05:20.5183015Z	2026-02-04T07:05:20.5183016Z	\N	\N	\N	\N
208e125e-6cec-4b83-a3ed-c8b1628e966f	d61f6fb1-d2cd-4350-b242-003ac3a4464f	login	User	d61f6fb1-d2cd-4350-b242-003ac3a4464f	\N	{"Email":"enf_do@telecuidar.com","LoginTime":"2026-02-04T07:48:43.3791698Z"}	127.0.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; pt-BR) WindowsPowerShell/5.1.26100.7462	2026-02-04T07:48:43.3792392Z	2026-02-04T07:48:43.3792394Z	\N	\N	\N	\N
88ba7c67-f402-46da-bc83-87abebfa9d4f	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	5ddeef0f-1ec9-473f-aaa2-b38dd51422d5	\N	{"RoomName":"5ddeef0f1ec9473faaa2b38dd51422d5","IsModerator":false,"Domain":"localhost:8443"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T07:05:25.5749738Z	2026-02-04T07:05:25.5749740Z	\N	\N	\N	\N
694e74ce-41da-4c3e-8672-17a6686a88f4	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	5ddeef0f-1ec9-473f-aaa2-b38dd51422d5	\N	{"RoomName":"5ddeef0f1ec9473faaa2b38dd51422d5","IsModerator":false,"Domain":"localhost:8443"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T07:07:11.4949087Z	2026-02-04T07:07:11.4949088Z	\N	\N	\N	\N
f59efcaf-bcf5-4978-9dd0-dd11b103a2fc	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	5ddeef0f-1ec9-473f-aaa2-b38dd51422d5	\N	{"RoomName":"5ddeef0f1ec9473faaa2b38dd51422d5","IsModerator":false,"Domain":"192.168.18.31:8443"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T07:08:35.9240271Z	2026-02-04T07:08:35.9240274Z	\N	\N	\N	\N
e06a829a-54c6-48aa-9e4a-0d8309048e0f	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	5ddeef0f-1ec9-473f-aaa2-b38dd51422d5	\N	{"RoomName":"5ddeef0f1ec9473faaa2b38dd51422d5","IsModerator":false,"Domain":"192.168.18.31:8443"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T07:11:02.2679387Z	2026-02-04T07:11:02.2679389Z	\N	\N	\N	\N
4c1e3daf-0f8b-4e42-a829-3535a01c624b	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	5ddeef0f-1ec9-473f-aaa2-b38dd51422d5	\N	{"RoomName":"5ddeef0f1ec9473faaa2b38dd51422d5","IsModerator":false,"Domain":"localhost:8443"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T07:13:15.4155755Z	2026-02-04T07:13:15.4155758Z	\N	\N	\N	\N
a88c3dee-dce3-4121-8ce8-4469732cc572	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	5ddeef0f-1ec9-473f-aaa2-b38dd51422d5	\N	{"RoomName":"5ddeef0f1ec9473faaa2b38dd51422d5","IsModerator":false,"Domain":"localhost:8443"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T07:13:19.4847861Z	2026-02-04T07:13:19.4847862Z	\N	\N	\N	\N
7b9d02ab-be9a-4c97-85c2-b3d21c32637d	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	login	User	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	\N	{"Email":"med_aj@telecuidar.com","LoginTime":"2026-02-04T07:15:44.6254861Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 Edg/144.0.0.0	2026-02-04T07:15:44.6346884Z	2026-02-04T07:15:44.6346891Z	\N	\N	\N	\N
d62af217-587c-4f7f-a85b-4b2a75aa695f	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	jitsi_access	Appointment	5ddeef0f-1ec9-473f-aaa2-b38dd51422d5	\N	{"RoomName":"5ddeef0f1ec9473faaa2b38dd51422d5","IsModerator":true,"Domain":"localhost:8443"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 Edg/144.0.0.0	2026-02-04T07:15:49.4899023Z	2026-02-04T07:15:49.4899030Z	\N	\N	\N	\N
c6586c9a-5c66-4b62-87e9-8c64e288a5d4	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	jitsi_access	Appointment	5ddeef0f-1ec9-473f-aaa2-b38dd51422d5	\N	{"RoomName":"5ddeef0f1ec9473faaa2b38dd51422d5","IsModerator":true,"Domain":"localhost:8443"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 Edg/144.0.0.0	2026-02-04T07:15:57.8176415Z	2026-02-04T07:15:57.8176416Z	\N	\N	\N	\N
ceb17f12-ce5c-407b-817c-48e3b1002872	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	5ddeef0f-1ec9-473f-aaa2-b38dd51422d5	\N	{"RoomName":"5ddeef0f1ec9473faaa2b38dd51422d5","IsModerator":false,"Domain":"192.168.18.31:8443"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T07:16:27.8799634Z	2026-02-04T07:16:27.8799635Z	\N	\N	\N	\N
cfb63518-e241-4a62-a08f-484a5881c342	d61f6fb1-d2cd-4350-b242-003ac3a4464f	login	User	d61f6fb1-d2cd-4350-b242-003ac3a4464f	\N	{"Email":"enf_do@telecuidar.com","LoginTime":"2026-02-04T07:17:22.0963323Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T07:17:22.0965640Z	2026-02-04T07:17:22.0965641Z	\N	\N	\N	\N
408d6a73-0661-400a-840f-6ad0ab03a9f2	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	5ddeef0f-1ec9-473f-aaa2-b38dd51422d5	\N	{"RoomName":"5ddeef0f1ec9473faaa2b38dd51422d5","IsModerator":false,"Domain":"localhost:8443"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T07:17:26.7305814Z	2026-02-04T07:17:26.7305815Z	\N	\N	\N	\N
0d9dacb7-4c40-42e7-acb9-5e036f876d5e	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	5ddeef0f-1ec9-473f-aaa2-b38dd51422d5	\N	{"RoomName":"5ddeef0f1ec9473faaa2b38dd51422d5","IsModerator":false,"Domain":"192.168.18.31:8443"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T07:22:10.7706829Z	2026-02-04T07:22:10.7706831Z	\N	\N	\N	\N
35be52dd-9f10-44e5-ae6a-071282f2faaf	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	5ddeef0f-1ec9-473f-aaa2-b38dd51422d5	\N	{"RoomName":"5ddeef0f1ec9473faaa2b38dd51422d5","IsModerator":false,"Domain":"192.168.18.31:8443"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T07:22:23.7824330Z	2026-02-04T07:22:23.7824335Z	\N	\N	\N	\N
8f9adb31-dd7f-4fb2-b7ea-682ed8d5a137	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	5ddeef0f-1ec9-473f-aaa2-b38dd51422d5	\N	{"RoomName":"5ddeef0f1ec9473faaa2b38dd51422d5","IsModerator":false,"Domain":"192.168.18.31:8443"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T07:24:54.5038675Z	2026-02-04T07:24:54.5038676Z	\N	\N	\N	\N
99976b8e-2061-4e44-98a3-222d5ef6af63	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	5ddeef0f-1ec9-473f-aaa2-b38dd51422d5	\N	{"RoomName":"5ddeef0f1ec9473faaa2b38dd51422d5","IsModerator":false,"Domain":"localhost:8443"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T07:25:08.4841964Z	2026-02-04T07:25:08.4841964Z	\N	\N	\N	\N
ce2ca024-068e-474f-8cba-5b532ad80e1c	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	5ddeef0f-1ec9-473f-aaa2-b38dd51422d5	\N	{"RoomName":"5ddeef0f1ec9473faaa2b38dd51422d5","IsModerator":false,"Domain":"192.168.18.31:8443"}	192.168.18.25	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T07:26:09.6727560Z	2026-02-04T07:26:09.6727562Z	\N	\N	\N	\N
f656f357-c2e6-41ff-83f0-be2bf2d4023f	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	5ddeef0f-1ec9-473f-aaa2-b38dd51422d5	\N	{"RoomName":"5ddeef0f1ec9473faaa2b38dd51422d5","IsModerator":false,"Domain":"localhost:8443"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T07:26:15.1912007Z	2026-02-04T07:26:15.1912008Z	\N	\N	\N	\N
1f62514d-b725-4ac3-98dd-4c442ead7c18	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	5ddeef0f-1ec9-473f-aaa2-b38dd51422d5	\N	{"RoomName":"5ddeef0f1ec9473faaa2b38dd51422d5","IsModerator":false,"Domain":"localhost:8443"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T07:31:12.4610967Z	2026-02-04T07:31:12.4610984Z	\N	\N	\N	\N
724b74cb-1e6b-44e6-9d79-944bd7ac0124	d61f6fb1-d2cd-4350-b242-003ac3a4464f	login	User	d61f6fb1-d2cd-4350-b242-003ac3a4464f	\N	{"Email":"enf_do@telecuidar.com","LoginTime":"2026-02-04T07:34:03.2384677Z"}	192.168.18.31	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 Edg/144.0.0.0	2026-02-04T07:34:03.2396630Z	2026-02-04T07:34:03.2396632Z	\N	\N	\N	\N
a383b877-324b-4c93-b6d0-757b5d9c6736	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	5ddeef0f-1ec9-473f-aaa2-b38dd51422d5	\N	{"RoomName":"5ddeef0f1ec9473faaa2b38dd51422d5","IsModerator":false,"Domain":"192.168.18.31:8443"}	192.168.18.31	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 Edg/144.0.0.0	2026-02-04T07:34:11.6388461Z	2026-02-04T07:34:11.6388463Z	\N	\N	\N	\N
b770cc93-99d6-4822-91ef-052d2b5aa2e9	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	5ddeef0f-1ec9-473f-aaa2-b38dd51422d5	\N	{"RoomName":"5ddeef0f1ec9473faaa2b38dd51422d5","IsModerator":false,"Domain":"192.168.18.31:8443"}	192.168.18.31	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 Edg/144.0.0.0	2026-02-04T07:34:56.7733959Z	2026-02-04T07:34:56.7733960Z	\N	\N	\N	\N
a850e4db-e77d-4df5-94ac-a319c6e1dd6d	d61f6fb1-d2cd-4350-b242-003ac3a4464f	login	User	d61f6fb1-d2cd-4350-b242-003ac3a4464f	\N	{"Email":"enf_do@telecuidar.com","LoginTime":"2026-02-04T07:38:42.1306462Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T07:38:42.1308029Z	2026-02-04T07:38:42.1308030Z	\N	\N	\N	\N
1966f13c-401c-4dd4-a574-e14d76e423cb	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	5ddeef0f-1ec9-473f-aaa2-b38dd51422d5	\N	{"RoomName":"5ddeef0f1ec9473faaa2b38dd51422d5","IsModerator":false,"Domain":"localhost:8443"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T07:38:46.5196447Z	2026-02-04T07:38:46.5196449Z	\N	\N	\N	\N
40c77e20-36e0-4069-a882-501521b15792	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	5ddeef0f-1ec9-473f-aaa2-b38dd51422d5	\N	{"RoomName":"5ddeef0f1ec9473faaa2b38dd51422d5","IsModerator":false,"Domain":"localhost:8443"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T07:42:34.6431820Z	2026-02-04T07:42:34.6431820Z	\N	\N	\N	\N
0df8a6c9-c134-4505-8471-f5b9749b7efb	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	5ddeef0f-1ec9-473f-aaa2-b38dd51422d5	\N	{"RoomName":"5ddeef0f1ec9473faaa2b38dd51422d5","IsModerator":false,"Domain":"localhost:8443"}	127.0.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; pt-BR) WindowsPowerShell/5.1.26100.7462	2026-02-04T07:48:43.3957718Z	2026-02-04T07:48:43.3957719Z	\N	\N	\N	\N
9902400b-e775-4ec2-b749-c458847181ff	d61f6fb1-d2cd-4350-b242-003ac3a4464f	login	User	d61f6fb1-d2cd-4350-b242-003ac3a4464f	\N	{"Email":"enf_do@telecuidar.com","LoginTime":"2026-02-04T07:50:05.3713517Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 Edg/144.0.0.0	2026-02-04T07:50:05.3714245Z	2026-02-04T07:50:05.3714246Z	\N	\N	\N	\N
722cbac3-bdf1-4595-9ef2-0c76e270ceef	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	5ddeef0f-1ec9-473f-aaa2-b38dd51422d5	\N	{"RoomName":"5ddeef0f1ec9473faaa2b38dd51422d5","IsModerator":false,"Domain":"localhost:8443"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 Edg/144.0.0.0	2026-02-04T07:50:11.5791379Z	2026-02-04T07:50:11.5791380Z	\N	\N	\N	\N
d73ddff9-4a3c-4363-b927-0f649087b7a6	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	5ddeef0f-1ec9-473f-aaa2-b38dd51422d5	\N	{"RoomName":"5ddeef0f1ec9473faaa2b38dd51422d5","IsModerator":false,"Domain":"localhost:8443"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 Edg/144.0.0.0	2026-02-04T07:50:18.1940567Z	2026-02-04T07:50:18.1940568Z	\N	\N	\N	\N
a6f2b39f-8b00-4c44-ac76-08c65dc2f23d	d61f6fb1-d2cd-4350-b242-003ac3a4464f	login	User	d61f6fb1-d2cd-4350-b242-003ac3a4464f	\N	{"Email":"enf_do@telecuidar.com","LoginTime":"2026-02-04T08:58:12.5747256Z"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T08:58:12.5787273Z	2026-02-04T08:58:12.5787274Z	\N	\N	\N	\N
06e3be28-ad34-4adf-9cc6-5b688808a755	d61f6fb1-d2cd-4350-b242-003ac3a4464f	jitsi_access	Appointment	5ddeef0f-1ec9-473f-aaa2-b38dd51422d5	\N	{"RoomName":"5ddeef0f1ec9473faaa2b38dd51422d5","IsModerator":false,"Domain":"localhost:8443"}	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-02-04T08:58:17.1386302Z	2026-02-04T08:58:17.1386303Z	\N	\N	\N	\N
\.


--
-- Data for Name: CboOccupations; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."CboOccupations" ("Id", "Code", "Name", "Family", "Subgroup", "AllowsTeleconsultation", "IsActive", "CreatedAt", "UpdatedAt") FROM stdin;
03e2f048-da04-4f76-8e6d-468d62e0283b	223236	Cirurgi├úo-dentista - ortodontista	Cirurgi├Áes-dentistas	Profissionais da sa├║de	1	1	2026-02-01 17:51:59.726454+00	2026-02-01 17:51:59.726455+00
08288f20-028b-4488-934f-85c9b48c83af	223545	Enfermeiro psiqui├ítrico	Enfermeiros	Profissionais da sa├║de	1	1	2026-02-01 17:51:59.726429+00	2026-02-01 17:51:59.726429+00
0d0bbf5d-3f38-40e1-9308-a85e22b4a138	251510	Psic├│logo cl├¡nico	Psic├│logos	Profissionais da sa├║de	1	1	2026-02-01 17:51:59.726433+00	2026-02-01 17:51:59.726433+00
141c7286-cb13-4e2a-885f-81e0e30c657a	223244	Cirurgi├úo-dentista - periodontista	Cirurgi├Áes-dentistas	Profissionais da sa├║de	1	1	2026-02-01 17:51:59.726455+00	2026-02-01 17:51:59.726456+00
1635c426-3aac-4e44-bc73-d8378f43b23d	225154	M├®dico pneumologista	M├®dicos especialistas	Profissionais da sa├║de	1	1	2026-02-01 17:51:59.726422+00	2026-02-01 17:51:59.726422+00
168478d0-ad13-4b2a-8df3-29609308f9c8	225157	M├®dico reumatologista	M├®dicos especialistas	Profissionais da sa├║de	1	1	2026-02-01 17:51:59.726424+00	2026-02-01 17:51:59.726424+00
20f3c6d2-5611-40ce-8950-d9e105f5e936	223625	Fisioterapeuta neurofuncional	Fisioterapeutas	Profissionais da sa├║de	1	1	2026-02-01 17:51:59.72644+00	2026-02-01 17:51:59.72644+00
2541599e-bda7-4b75-81b5-d019a786b6ad	223505	Enfermeiro	Enfermeiros	Profissionais da sa├║de	1	1	2026-02-01 17:51:59.726425+00	2026-02-01 17:51:59.726425+00
26267d79-b61b-4744-b412-d7be1a04710a	223610	Fisioterapeuta acupunturista	Fisioterapeutas	Profissionais da sa├║de	1	1	2026-02-01 17:51:59.726438+00	2026-02-01 17:51:59.726438+00
36afcabc-a9df-4ec3-bb2b-c699cf52b76d	223555	Enfermeiro sanitarista	Enfermeiros	Profissionais da sa├║de	1	1	2026-02-01 17:51:59.72643+00	2026-02-01 17:51:59.72643+00
39d81ad6-2cef-42c1-877d-289d33298115	223605	Fisioterapeuta geral	Fisioterapeutas	Profissionais da sa├║de	1	1	2026-02-01 17:51:59.726437+00	2026-02-01 17:51:59.726437+00
3d4a643b-6b30-4894-a7c9-ff190d786c81	251535	Neuropsic├│logo	Psic├│logos	Profissionais da sa├║de	1	1	2026-02-01 17:51:59.726436+00	2026-02-01 17:51:59.726437+00
3e8f0b2c-d214-49a6-800d-d33f23f84a0a	225121	M├®dico ginecologista e obstetra	M├®dicos especialistas	Profissionais da sa├║de	1	1	2026-02-01 17:51:59.726404+00	2026-02-01 17:51:59.726404+00
3ff9b87e-05af-4ee7-b321-1dac4f6affd8	225155	M├®dico psiquiatra	M├®dicos especialistas	Profissionais da sa├║de	1	1	2026-02-01 17:51:59.726424+00	2026-02-01 17:51:59.726424+00
402c9368-8e40-47c0-b432-8e8c982ac2d2	223232	Cirurgi├úo-dentista - odontopediatra	Cirurgi├Áes-dentistas	Profissionais da sa├║de	1	1	2026-02-01 17:51:59.726445+00	2026-02-01 17:51:59.726445+00
43b4a33f-fa93-4f14-93d2-8ce2e9fecab8	225130	M├®dico de fam├¡lia e comunidade	M├®dicos cl├¡nicos	Profissionais da sa├║de	1	1	2026-02-01 17:51:59.726399+00	2026-02-01 17:51:59.726399+00
4574ffc1-4d11-4234-b026-753165405dcd	251525	Psic├│logo jur├¡dico	Psic├│logos	Profissionais da sa├║de	1	1	2026-02-01 17:51:59.726436+00	2026-02-01 17:51:59.726436+00
45f82d06-8b70-4393-95fb-76be0d1c3980	223224	Cirurgi├úo-dentista - implantodontista	Cirurgi├Áes-dentistas	Profissionais da sa├║de	1	1	2026-02-01 17:51:59.726444+00	2026-02-01 17:51:59.726444+00
5a62e539-728e-4b7a-948e-6f88694af912	223510	Enfermeiro auditor	Enfermeiros	Profissionais da sa├║de	1	1	2026-02-01 17:51:59.726425+00	2026-02-01 17:51:59.726425+00
5e245e12-df75-455f-83a1-1e267ea5cf07	251515	Psic├│logo do esporte	Psic├│logos	Profissionais da sa├║de	1	1	2026-02-01 17:51:59.726435+00	2026-02-01 17:51:59.726435+00
633aded5-6219-40f1-8688-995acd1eaaa4	225139	M├®dico oftalmologista	M├®dicos especialistas	Profissionais da sa├║de	1	1	2026-02-01 17:51:59.72642+00	2026-02-01 17:51:59.72642+00
657a192c-47a6-4574-a2b6-ae061174c0a1	223520	Enfermeiro de centro cir├║rgico	Enfermeiros	Profissionais da sa├║de	0	1	2026-02-01 17:51:59.726426+00	2026-02-01 17:51:59.726426+00
66ac614a-9ce7-41cd-a355-927d18448849	223256	Cirurgi├úo-dentista - traumatologista bucomaxilofacial	Cirurgi├Áes-dentistas	Profissionais da sa├║de	0	1	2026-02-01 17:51:59.726457+00	2026-02-01 17:51:59.726457+00
67f6d774-441b-45d0-ac69-7a845b72b6bd	251520	Psic├│logo hospitalar	Psic├│logos	Profissionais da sa├║de	1	1	2026-02-01 17:51:59.726435+00	2026-02-01 17:51:59.726435+00
6c3e0a20-246a-4313-a27a-0a75d269a0b3	223710	Nutricionista	Nutricionistas	Profissionais da sa├║de	1	1	2026-02-01 17:51:59.726437+00	2026-02-01 17:51:59.726437+00
7135e339-38ab-421a-952b-7edeeae28bf1	225118	M├®dico geriatra	M├®dicos especialistas	Profissionais da sa├║de	1	1	2026-02-01 17:51:59.726403+00	2026-02-01 17:51:59.726403+00
7177a9df-3c8d-4c2a-9e3f-cb10ad473a03	223540	Enfermeiro obst├®trico	Enfermeiros	Profissionais da sa├║de	1	1	2026-02-01 17:51:59.726429+00	2026-02-01 17:51:59.726429+00
72f168d0-71bc-4e43-8812-4990ca2f4f7b	225148	M├®dico otorrinolaringologista	M├®dicos especialistas	Profissionais da sa├║de	1	1	2026-02-01 17:51:59.726421+00	2026-02-01 17:51:59.726421+00
770f6d5e-ffe8-40b2-8fe0-c40d9195f550	223630	Fisioterapeuta respirat├│rio	Fisioterapeutas	Profissionais da sa├║de	1	1	2026-02-01 17:51:59.72644+00	2026-02-01 17:51:59.72644+00
7a4d38cc-9f1e-44bf-8729-b434833ca170	223515	Enfermeiro de bordo	Enfermeiros	Profissionais da sa├║de	0	1	2026-02-01 17:51:59.726426+00	2026-02-01 17:51:59.726426+00
7af16944-2d30-442e-aeeb-141e658395d7	225160	M├®dico urologista	M├®dicos especialistas	Profissionais da sa├║de	1	1	2026-02-01 17:51:59.726425+00	2026-02-01 17:51:59.726425+00
7e031ff3-4470-40f1-8fed-1895caf0b70a	225112	M├®dico endocrinologista	M├®dicos especialistas	Profissionais da sa├║de	1	1	2026-02-01 17:51:59.726401+00	2026-02-01 17:51:59.726401+00
825faa27-d20f-460d-b601-53dd3b28dc5f	223252	Cirurgi├úo-dentista - radiologista	Cirurgi├Áes-dentistas	Profissionais da sa├║de	1	1	2026-02-01 17:51:59.726457+00	2026-02-01 17:51:59.726457+00
82a754ca-52c6-428a-9861-3e68e6458e07	223405	Farmac├¬utico	Farmac├¬uticos	Profissionais da sa├║de	1	1	2026-02-01 17:51:59.726458+00	2026-02-01 17:51:59.726458+00
88c124c2-5f86-4ff8-adfe-afb0cf712b30	223535	Enfermeiro neonatologista	Enfermeiros	Profissionais da sa├║de	1	1	2026-02-01 17:51:59.726428+00	2026-02-01 17:51:59.726428+00
8c5ac377-734a-4d64-910d-483a19fe5171	225145	M├®dico ortopedista	M├®dicos especialistas	Profissionais da sa├║de	1	1	2026-02-01 17:51:59.726421+00	2026-02-01 17:51:59.726421+00
8e9417f3-d1c2-478c-b507-d56712d16b65	223220	Cirurgi├úo-dentista - epidemiologista	Cirurgi├Áes-dentistas	Profissionais da sa├║de	1	1	2026-02-01 17:51:59.726443+00	2026-02-01 17:51:59.726443+00
90320d81-aee5-440e-8842-cfc268ba3792	223810	Fonoaudi├│logo	Fonoaudi├│logos	Profissionais da sa├║de	1	1	2026-02-01 17:51:59.726441+00	2026-02-01 17:51:59.726441+00
92e672a5-961a-4dbd-b1aa-7917dde5a392	251530	Psic├│logo do trabalho	Psic├│logos	Profissionais da sa├║de	1	1	2026-02-01 17:51:59.726436+00	2026-02-01 17:51:59.726436+00
9314f338-7085-4849-9f8a-a5835428e50f	223530	Enfermeiro do trabalho	Enfermeiros	Profissionais da sa├║de	1	1	2026-02-01 17:51:59.726428+00	2026-02-01 17:51:59.726428+00
99cc083b-c62e-4875-a0c7-3f31e94eb7b3	223905	Terapeuta ocupacional	Terapeutas ocupacionais	Profissionais da sa├║de	1	1	2026-02-01 17:51:59.726441+00	2026-02-01 17:51:59.726441+00
a00806b5-50d7-4048-b8e5-02aa689b6b02	225133	M├®dico nefrologista	M├®dicos especialistas	Profissionais da sa├║de	1	1	2026-02-01 17:51:59.726419+00	2026-02-01 17:51:59.726419+00
a59cffc3-3830-43b9-bf5f-4e0ae18b4c0c	225115	M├®dico gastroenterologista	M├®dicos especialistas	Profissionais da sa├║de	1	1	2026-02-01 17:51:59.726403+00	2026-02-01 17:51:59.726403+00
ae617d4d-7dd5-4474-a06e-f0e052733e52	225151	M├®dico pediatra	M├®dicos especialistas	Profissionais da sa├║de	1	1	2026-02-01 17:51:59.726422+00	2026-02-01 17:51:59.726422+00
af8d7402-90e9-410a-891d-e8ea51114167	225136	M├®dico neurologista	M├®dicos especialistas	Profissionais da sa├║de	1	1	2026-02-01 17:51:59.72642+00	2026-02-01 17:51:59.72642+00
b522ba33-8819-43e6-88f9-c524f73a40b4	251605	Assistente social	Assistentes sociais	Profissionais da sa├║de	1	1	2026-02-01 17:51:59.726458+00	2026-02-01 17:51:59.726458+00
b569563f-c807-4ce4-bac4-cd5be3765a38	223248	Cirurgi├úo-dentista - protesi├│logo bucomaxilofacial	Cirurgi├Áes-dentistas	Profissionais da sa├║de	1	1	2026-02-01 17:51:59.726456+00	2026-02-01 17:51:59.726456+00
b5ce2444-92da-4436-97ee-249166735f59	225103	M├®dico cardiologista	M├®dicos especialistas	Profissionais da sa├║de	1	1	2026-02-01 17:51:59.7264+00	2026-02-01 17:51:59.7264+00
b7df1e4a-f424-4c3a-ad15-04bb5057f42c	223615	Fisioterapeuta do trabalho	Fisioterapeutas	Profissionais da sa├║de	1	1	2026-02-01 17:51:59.726439+00	2026-02-01 17:51:59.726439+00
c9e55051-88c7-4e87-8ff3-45fca6317747	225125	M├®dico cl├¡nico	M├®dicos cl├¡nicos	Profissionais da sa├║de	1	1	2026-02-01 17:51:59.726126+00	2026-02-01 17:51:59.726126+00
cc3f93b8-b89a-472b-825f-ba25608d18f8	223212	Cirurgi├úo-dentista - cl├¡nico geral	Cirurgi├Áes-dentistas	Profissionais da sa├║de	1	1	2026-02-01 17:51:59.726442+00	2026-02-01 17:51:59.726442+00
cfc7e6be-254f-4850-a65a-7aee1908a6ce	223216	Cirurgi├úo-dentista - endodontista	Cirurgi├Áes-dentistas	Profissionais da sa├║de	1	1	2026-02-01 17:51:59.726443+00	2026-02-01 17:51:59.726443+00
db3d236f-92f2-4e33-b801-031ba66cf067	223525	Enfermeiro de terapia intensiva	Enfermeiros	Profissionais da sa├║de	1	1	2026-02-01 17:51:59.726427+00	2026-02-01 17:51:59.726427+00
dce23265-85b2-4aee-83bc-4a31b9ad124b	225142	M├®dico oncologista	M├®dicos especialistas	Profissionais da sa├║de	1	1	2026-02-01 17:51:59.726421+00	2026-02-01 17:51:59.726421+00
ddaa0fea-1e49-4b4a-8d98-462e69a01efc	223208	Cirurgi├úo-dentista	Cirurgi├Áes-dentistas	Profissionais da sa├║de	1	1	2026-02-01 17:51:59.726441+00	2026-02-01 17:51:59.726442+00
dfda58c6-14e9-4ce5-840f-8ce65b26ad76	223550	Enfermeiro puericultor e pedi├ítrico	Enfermeiros	Profissionais da sa├║de	1	1	2026-02-01 17:51:59.72643+00	2026-02-01 17:51:59.72643+00
edda1737-343e-4df9-a16b-892e2772b34d	223240	Cirurgi├úo-dentista - patologista bucal	Cirurgi├Áes-dentistas	Profissionais da sa├║de	1	1	2026-02-01 17:51:59.726455+00	2026-02-01 17:51:59.726455+00
ee6ee9b8-ac5b-4b8a-a1bf-68e0f70426fd	223620	Fisioterapeuta esportivo	Fisioterapeutas	Profissionais da sa├║de	1	1	2026-02-01 17:51:59.726439+00	2026-02-01 17:51:59.726439+00
f35a8e0d-eb46-4b81-8a60-fada45cbad3c	225109	M├®dico dermatologista	M├®dicos especialistas	Profissionais da sa├║de	1	1	2026-02-01 17:51:59.726401+00	2026-02-01 17:51:59.726401+00
f6d8f0cd-e4a1-4b72-b88b-629c5c04302b	225127	M├®dico infectologista	M├®dicos especialistas	Profissionais da sa├║de	1	1	2026-02-01 17:51:59.726404+00	2026-02-01 17:51:59.726404+00
fc20d0c2-5bb5-4702-a88d-f2520a47d7ad	223560	Enfermeiro de sa├║de da fam├¡lia	Enfermeiros	Profissionais da sa├║de	1	1	2026-02-01 17:51:59.72643+00	2026-02-01 17:51:59.72643+00
ff423673-854d-4477-b862-b182059337c5	223228	Cirurgi├úo-dentista - odontogeriatra	Cirurgi├Áes-dentistas	Profissionais da sa├║de	1	1	2026-02-01 17:51:59.726444+00	2026-02-01 17:51:59.726444+00
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
fff29f5f-77e9-471e-b7a9-0e4826b48356	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	­ƒôà Nova Consulta Agendada	Uma consulta foi agendada com Daniel Carrara para 04/02/2026 03:00	Info	0	\N	2026-02-04T06:15:41.1044698Z	2026-02-04T06:15:41.1044702Z
db6afd23-892c-4b3c-93cc-b22114fda992	5e764cc6-20b0-4c26-a342-0083beb4b229	ÔØî Sua Consulta foi Cancelada	Sua consulta com Dr(a) Cl├íudio Amantino foi cancelada.	Warning	0	\N	2026-02-02T22:47:16.7228923Z	2026-02-02T22:47:16.7228926Z
c5cf3687-2685-4ff5-967f-3d7908212437	5e764cc6-20b0-4c26-a342-0083beb4b229	ÔØî Sua Consulta foi Cancelada	Sua consulta com Dr(a) Daniela Ochoa foi cancelada.	Warning	0	\N	2026-02-02T22:47:19.8194603Z	2026-02-02T22:47:19.8194617Z
41a34a6b-c1f9-40c7-ac45-3d6dc93c00f6	5e764cc6-20b0-4c26-a342-0083beb4b229	ÔØî Sua Consulta foi Cancelada	Sua consulta com Dr(a) Daniela Ochoa foi cancelada.	Warning	0	\N	2026-02-02T22:47:22.0303279Z	2026-02-02T22:47:22.0303280Z
29da6988-e3a2-4a6b-baf5-84eba443b611	5e764cc6-20b0-4c26-a342-0083beb4b229	ÔØî Sua Consulta foi Cancelada	Sua consulta com Dr(a) Cl├íudio Amantino foi cancelada.	Warning	0	\N	2026-02-02T22:47:23.9506377Z	2026-02-02T22:47:23.9506379Z
89bdce9f-f680-48e1-bde8-765a248304cb	6bf6f665-96ba-4aae-8a65-cfba0624bd49	ÔØî Sua Consulta foi Cancelada	Sua consulta com Dr(a) Cl├íudio Amantino foi cancelada.	Warning	0	\N	2026-02-02T22:47:26.5128616Z	2026-02-02T22:47:26.5128616Z
9988ada0-00db-4591-b19b-44e8a879ee08	6bf6f665-96ba-4aae-8a65-cfba0624bd49	ÔØî Sua Consulta foi Cancelada	Sua consulta com Dr(a) Daniela Ochoa foi cancelada.	Warning	0	\N	2026-02-02T22:47:28.8858261Z	2026-02-02T22:47:28.8858262Z
596e7c9e-13ad-4c4f-be7b-7f7a3f13672c	6bf6f665-96ba-4aae-8a65-cfba0624bd49	ÔØî Sua Consulta foi Cancelada	Sua consulta com Dr(a) Daniela Ochoa foi cancelada.	Warning	0	\N	2026-02-02T22:47:30.6150218Z	2026-02-02T22:47:30.6150219Z
59337385-5d83-4bb7-9a6b-3ec14e28f753	6f3a6731-435d-4f76-b725-42c993f2797c	ÔØî Consulta Cancelada	A consulta com Cl├íudio Amantino agendada para 06/02/2026 00:00 foi cancelada.	Warning	0	\N	2026-02-02T22:47:32.3400095Z	2026-02-02T22:47:32.3400097Z
4e40e906-e70c-4b5e-a425-e47e507b7c5f	5e764cc6-20b0-4c26-a342-0083beb4b229	ÔØî Sua Consulta foi Cancelada	Sua consulta com Dr(a) Geraldo Tadeu foi cancelada.	Warning	0	\N	2026-02-02T22:47:32.3463265Z	2026-02-02T22:47:32.3463266Z
f28f6aba-292c-4ea9-8233-328aa3d0ec9f	6f3a6731-435d-4f76-b725-42c993f2797c	ÔØî Consulta Cancelada	A consulta com Cl├íudio Amantino agendada para 06/02/2026 00:00 foi cancelada.	Warning	0	\N	2026-02-02T22:47:34.0777471Z	2026-02-02T22:47:34.0777471Z
cab93217-2593-4dfc-b1e1-703d5f932a99	5e764cc6-20b0-4c26-a342-0083beb4b229	ÔØî Sua Consulta foi Cancelada	Sua consulta com Dr(a) Geraldo Tadeu foi cancelada.	Warning	0	\N	2026-02-02T22:47:34.0818785Z	2026-02-02T22:47:34.0818786Z
d15d359d-076e-4d24-ab44-2ac3b2340854	0b3b0ee6-1eec-4598-9d30-09442a923ae1	ÔØî Sua Consulta foi Cancelada	Sua consulta com Dr(a) Daniela Ochoa foi cancelada.	Warning	0	\N	2026-02-02T22:47:36.1025314Z	2026-02-02T22:47:36.1025314Z
8a35709e-f479-408f-8266-734f38db164d	6bf6f665-96ba-4aae-8a65-cfba0624bd49	ÔØî Sua Consulta foi Cancelada	Sua consulta com Dr(a) Cl├íudio Amantino foi cancelada.	Warning	0	\N	2026-02-02T22:47:41.6006696Z	2026-02-02T22:47:41.6006698Z
df7293be-ee0e-4c06-b2ab-8eb62ec57b64	6f3a6731-435d-4f76-b725-42c993f2797c	ÔØî Consulta Cancelada	A consulta com Daniel Carrara agendada para 05/02/2026 00:00 foi cancelada.	Warning	0	\N	2026-02-02T22:47:44.7440410Z	2026-02-02T22:47:44.7440412Z
1f99925c-6115-42da-a82d-9312afefb1b7	6bf6f665-96ba-4aae-8a65-cfba0624bd49	ÔØî Sua Consulta foi Cancelada	Sua consulta com Dr(a) Geraldo Tadeu foi cancelada.	Warning	0	\N	2026-02-02T22:47:44.7483527Z	2026-02-02T22:47:44.7483528Z
8d559913-96d7-47cc-b028-a05312c14da7	0b3b0ee6-1eec-4598-9d30-09442a923ae1	ÔØî Sua Consulta foi Cancelada	Sua consulta com Dr(a) Cl├íudio Amantino foi cancelada.	Warning	0	\N	2026-02-02T22:47:46.4964028Z	2026-02-02T22:47:46.4964028Z
75f21a08-0570-4746-90f8-535c402c30db	5e764cc6-20b0-4c26-a342-0083beb4b229	ÔØî Sua Consulta foi Cancelada	Sua consulta com Dr(a) Daniel Carrara foi cancelada.	Warning	0	\N	2026-02-02T22:47:49.2616895Z	2026-02-02T22:47:49.2616896Z
5d9b3134-c323-4947-be44-f5f81136d29a	5e764cc6-20b0-4c26-a342-0083beb4b229	ÔØî Sua Consulta foi Cancelada	Sua consulta com Dr(a) Ant├┤nio Jorge foi cancelada.	Warning	0	\N	2026-02-02T22:47:55.6821032Z	2026-02-02T22:47:55.6821033Z
0ab0ebc9-8a12-495f-9cec-049cea687521	5e764cc6-20b0-4c26-a342-0083beb4b229	ÔØî Sua Consulta foi Cancelada	Sua consulta com Dr(a) Ant├┤nio Jorge foi cancelada.	Warning	0	\N	2026-02-02T22:47:57.8850413Z	2026-02-02T22:47:57.8850415Z
b3185a6b-4399-49af-be21-a64e27005406	6bf6f665-96ba-4aae-8a65-cfba0624bd49	ÔØî Sua Consulta foi Cancelada	Sua consulta com Dr(a) Daniel Carrara foi cancelada.	Warning	0	\N	2026-02-02T22:48:05.4842012Z	2026-02-02T22:48:05.4842012Z
7b354de0-716c-4da4-97bd-826e9a1de115	0b3b0ee6-1eec-4598-9d30-09442a923ae1	ÔØî Sua Consulta foi Cancelada	Sua consulta com Dr(a) Geraldo Tadeu foi cancelada.	Warning	0	\N	2026-02-02T22:48:07.4167451Z	2026-02-02T22:48:07.4167453Z
d8711583-1314-4d5b-904e-eddfbe0c156b	6bf6f665-96ba-4aae-8a65-cfba0624bd49	ÔØî Sua Consulta foi Cancelada	Sua consulta com Dr(a) Ant├┤nio Jorge foi cancelada.	Warning	0	\N	2026-02-02T22:48:10.8320081Z	2026-02-02T22:48:10.8320081Z
271dc7c2-4faf-4042-b93c-5796f69e5fa1	6f3a6731-435d-4f76-b725-42c993f2797c	ÔØî Consulta Cancelada	A consulta com Daniel Carrara agendada para 04/02/2026 00:00 foi cancelada.	Warning	0	\N	2026-02-02T22:48:12.4769364Z	2026-02-02T22:48:12.4769372Z
6ad05109-27a1-4fb3-b51b-90c031acb19f	6f3a6731-435d-4f76-b725-42c993f2797c	ÔØî Consulta Cancelada	A consulta com Geraldo Tadeu agendada para 04/02/2026 00:00 foi cancelada.	Warning	0	\N	2026-02-02T22:48:15.4417203Z	2026-02-02T22:48:15.4417204Z
d721a9f2-6415-4d4d-af5b-765c236c317a	6f3a6731-435d-4f76-b725-42c993f2797c	ÔØî Consulta Cancelada	A consulta com Daniela Ochoa agendada para 04/02/2026 00:00 foi cancelada.	Warning	0	\N	2026-02-02T22:48:18.7816763Z	2026-02-02T22:48:18.7816764Z
c1ae5076-e86f-4038-8689-d3fa8a7cc305	6bf6f665-96ba-4aae-8a65-cfba0624bd49	ÔØî Sua Consulta foi Cancelada	Sua consulta com Dr(a) Ant├┤nio Jorge foi cancelada.	Warning	0	\N	2026-02-02T22:48:44.1570654Z	2026-02-02T22:48:44.1570657Z
67e5ccaa-2569-427e-8893-e62c4f886834	6f3a6731-435d-4f76-b725-42c993f2797c	ÔØî Consulta Cancelada	A consulta com Daniela Ochoa agendada para 04/02/2026 00:00 foi cancelada.	Warning	0	\N	2026-02-02T22:48:07.4118497Z	2026-02-02T22:48:07.4118511Z
688ce5a6-d1a7-493c-958f-c3861bf87678	6bf6f665-96ba-4aae-8a65-cfba0624bd49	ÔØî Sua Consulta foi Cancelada	Sua consulta com Dr(a) Geraldo Tadeu foi cancelada.	Warning	0	\N	2026-02-02T22:48:12.4811212Z	2026-02-02T22:48:12.4811212Z
6bf5fc9d-5063-47c3-a73c-833c23bbabaa	0b3b0ee6-1eec-4598-9d30-09442a923ae1	ÔØî Sua Consulta foi Cancelada	Sua consulta com Dr(a) Geraldo Tadeu foi cancelada.	Warning	0	\N	2026-02-02T22:48:18.8117112Z	2026-02-02T22:48:18.8117117Z
eb31b3ae-2d38-46c0-a5bb-ca015022bcae	0b3b0ee6-1eec-4598-9d30-09442a923ae1	ÔØî Sua Consulta foi Cancelada	Sua consulta com Dr(a) Ant├┤nio Jorge foi cancelada.	Warning	0	\N	2026-02-02T22:48:26.9211402Z	2026-02-02T22:48:26.9211404Z
22387c43-fa4d-47e0-a316-ed6244ee72ad	0b3b0ee6-1eec-4598-9d30-09442a923ae1	ÔØî Sua Consulta foi Cancelada	Sua consulta com Dr(a) Ant├┤nio Jorge foi cancelada.	Warning	0	\N	2026-02-02T22:48:28.6046397Z	2026-02-02T22:48:28.6046398Z
e1526c5d-d888-46b0-917b-fe1db45a4fa4	6bf6f665-96ba-4aae-8a65-cfba0624bd49	ÔØî Sua Consulta foi Cancelada	Sua consulta com Dr(a) Daniel Carrara foi cancelada.	Warning	0	\N	2026-02-02T22:48:36.7660053Z	2026-02-02T22:48:36.7660064Z
7179364e-c2eb-4b3d-97a9-77ad164c216f	6f3a6731-435d-4f76-b725-42c993f2797c	ÔØî Consulta Cancelada	A consulta com Ant├┤nio Jorge agendada para 02/02/2026 00:00 foi cancelada.	Warning	0	\N	2026-02-02T22:48:55.2371731Z	2026-02-02T22:48:55.2371732Z
27f1e50e-d49f-4fe4-8d4f-f7b904e2c6bf	6f3a6731-435d-4f76-b725-42c993f2797c	ÔØî Consulta Cancelada	A consulta com Geraldo Tadeu agendada para 03/02/2026 00:00 foi cancelada.	Warning	0	\N	2026-02-02T22:48:41.6397894Z	2026-02-02T22:48:41.6397903Z
613720b6-0149-4ad9-9e09-4a8b27cf3bf2	6f3a6731-435d-4f76-b725-42c993f2797c	ÔØî Consulta Cancelada	A consulta com Ant├┤nio Jorge agendada para 02/02/2026 00:00 foi cancelada.	Warning	0	\N	2026-02-02T22:54:27.6974352Z	2026-02-02T22:54:27.6974353Z
49604195-3789-4dee-8ac2-bc291030d50c	0b3b0ee6-1eec-4598-9d30-09442a923ae1	ÔØî Sua Consulta foi Cancelada	Sua consulta com Dr(a) Daniel Carrara foi cancelada.	Warning	0	\N	2026-02-02T22:54:56.3963953Z	2026-02-02T22:54:56.3963953Z
ac154c08-ef38-44c0-9ff9-6b4d6ddcb06c	6bf6f665-96ba-4aae-8a65-cfba0624bd49	ÔØî Sua Consulta foi Cancelada	Sua consulta com Dr(a) Ant├┤nio Jorge foi cancelada.	Warning	0	\N	2026-02-02T22:55:12.3830917Z	2026-02-02T22:55:12.3830918Z
25c3e138-e959-47c7-95b9-3d59cc2c63e2	0b3b0ee6-1eec-4598-9d30-09442a923ae1	ÔØî Sua Consulta foi Cancelada	Sua consulta com Dr(a) Ant├┤nio Jorge foi cancelada.	Warning	0	\N	2026-02-02T22:55:16.2712062Z	2026-02-02T22:55:16.2712067Z
\.


--
-- Data for Name: PatientProfiles; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."PatientProfiles" ("Id", "UserId", "Cns", "SocialName", "Gender", "BirthDate", "MotherName", "FatherName", "Nationality", "ZipCode", "Address", "City", "State", "CreatedAt", "UpdatedAt") FROM stdin;
d45bfea4-02b1-435a-adb5-fc7e246848a5	6bf6f665-96ba-4aae-8a65-cfba0624bd49	719806625334931	\N	M	1972-04-02T16:09:12.2182007-03:00	\N	\N	\N	\N	\N	\N	\N	2026-02-02T19:09:12.2181980Z	2026-02-02T19:09:12.2181981Z
e087a437-ba37-45e3-9b94-1cb0cfbbdec0	0b3b0ee6-1eec-4598-9d30-09442a923ae1	730484628793231	\N	F	1977-09-10T16:09:12.2181424-03:00	\N	\N	\N	\N	\N	\N	\N	2026-02-02T19:09:12.2181386Z	2026-02-02T19:09:12.2181387Z
fdb7c053-d4eb-46ce-aace-d661d873c08e	5e764cc6-20b0-4c26-a342-0083beb4b229	711104447782693	\N	M	1976-12-19T16:09:12.2182671-02:00	\N	\N	\N	\N	\N	\N	\N	2026-02-02T19:09:12.2182645Z	2026-02-02T19:09:12.2182646Z
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
16ec48ed-1b91-4f86-b73e-621434b14e1c	CRM	Conselho Regional de Medicina	Medicina	1	2026-02-01 17:51:59.648831+00	2026-02-01 17:51:59.648832+00
25b5d5a8-0269-428a-b10e-e6ac2acb246e	CRMV	Conselho Regional de Medicina Veterin├íria	Medicina Veterin├íria	1	2026-02-01 17:51:59.649062+00	2026-02-01 17:51:59.649062+00
2852b658-e3df-4760-95df-e35754966cd6	CRFA	Conselho Regional de Fonoaudiologia	Fonoaudiologia	1	2026-02-01 17:51:59.649056+00	2026-02-01 17:51:59.649056+00
2d4bd5e6-8b14-4b24-bab3-2a8927d016f5	CRBIO	Conselho Regional de Biologia	Biologia	1	2026-02-01 17:51:59.64906+00	2026-02-01 17:51:59.64906+00
3a817559-d5ba-42f8-a6bf-fdcb8ef88234	CRP	Conselho Regional de Psicologia	Psicologia	1	2026-02-01 17:51:59.649054+00	2026-02-01 17:51:59.649054+00
48cdfad1-c16f-4f42-9a1e-d1ee1fe35004	CRQ	Conselho Regional de Qu├¡mica	Qu├¡mica	1	2026-02-01 17:51:59.649061+00	2026-02-01 17:51:59.649061+00
4c92eb34-53c3-4829-9d75-9deb9eef8e57	CRN	Conselho Regional de Nutri├º├úo	Nutri├º├úo	1	2026-02-01 17:51:59.649056+00	2026-02-01 17:51:59.649057+00
55f1a9dd-8b7e-4398-a684-5e6e80384a0b	CRESS	Conselho Regional de Servi├ºo Social	Servi├ºo Social	1	2026-02-01 17:51:59.649059+00	2026-02-01 17:51:59.649059+00
6c5f7eb7-3590-4456-9cd3-abb90c3d1e3e	CREFITO	Conselho Regional de Fisioterapia e Terapia Ocupacional	Fisioterapia	1	2026-02-01 17:51:59.649054+00	2026-02-01 17:51:59.649054+00
6d1ffccc-44e1-4022-890a-85fad29f27cb	CRF	Conselho Regional de Farm├ícia	Farm├ícia	1	2026-02-01 17:51:59.649059+00	2026-02-01 17:51:59.649059+00
6e033a60-d1f5-4b18-85d1-6c8e13d1c040	COREN	Conselho Regional de Enfermagem	Enfermagem	1	2026-02-01 17:51:59.649053+00	2026-02-01 17:51:59.649053+00
9a0a0ebf-822e-4775-a01f-ce520c6838ca	CRBM	Conselho Regional de Biomedicina	Biomedicina	1	2026-02-01 17:51:59.64906+00	2026-02-01 17:51:59.64906+00
b99c870e-324f-483d-97b5-cdf3dd6a09c7	CREF	Conselho Regional de Educa├º├úo F├¡sica	Educa├º├úo F├¡sica	1	2026-02-01 17:51:59.649061+00	2026-02-01 17:51:59.649061+00
da07a361-e827-4dd3-862a-4fb7bf3e019a	CRO	Conselho Regional de Odontologia	Odontologia	1	2026-02-01 17:51:59.649054+00	2026-02-01 17:51:59.649054+00
e2ac40ed-87d0-49c4-8bae-40abbdc46363	CRTR	Conselho Regional de T├®cnicos em Radiologia	Radiologia	1	2026-02-01 17:51:59.649061+00	2026-02-01 17:51:59.649061+00
\.


--
-- Data for Name: ProfessionalProfiles; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."ProfessionalProfiles" ("Id", "UserId", "Crm", "Cbo", "SpecialtyId", "Gender", "BirthDate", "Nationality", "ZipCode", "Address", "City", "State", "CreatedAt", "UpdatedAt", "CboOccupationId", "CouncilId", "CouncilRegistration", "CouncilState") FROM stdin;
44999e6f-2c57-4af0-b72f-b0bc7bb0cb19	6f3a6731-435d-4f76-b725-42c993f2797c	\N	\N	3adebdb2-f9e3-476d-beba-3957684cd13f	M	1986-05-29T16:09:12.1047673-03:00	\N	\N	\N	\N	\N	2026-02-02T19:09:12.1047502Z	2026-02-02T19:09:12.1047507Z	\N	16ec48ed-1b91-4f86-b73e-621434b14e1c	158094	MG
98d50c0f-9a5c-4cf4-9ea6-0b8ca6a5cd25	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	\N	\N	48e0503f-d0a3-4702-b050-66d4c20b6d6d	M	1989-12-11T16:09:12.0569780-02:00	\N	\N	\N	\N	\N	2026-02-02T19:09:12.0565385Z	2026-02-02T19:09:12.0565388Z	\N	16ec48ed-1b91-4f86-b73e-621434b14e1c	173993	MG
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
70dfb689-ab3d-439c-9986-8470b051b464	a06cbf1d-2661-49ff-bbfb-0041b02dae5e	{"TimeRange":{"StartTime":"08:00","EndTime":"17:00"},"BreakTime":null,"ConsultationDuration":30,"IntervalBetweenConsultations":5}	[{"Day":"Monday","IsWorking":true,"TimeRange":{"StartTime":"08:00","EndTime":"17:00"},"BreakTime":null,"ConsultationDuration":30,"IntervalBetweenConsultations":5,"Customized":false},{"Day":"Tuesday","IsWorking":true,"TimeRange":{"StartTime":"08:00","EndTime":"17:00"},"BreakTime":null,"ConsultationDuration":30,"IntervalBetweenConsultations":5,"Customized":false},{"Day":"Wednesday","IsWorking":true,"TimeRange":{"StartTime":"08:00","EndTime":"17:00"},"BreakTime":null,"ConsultationDuration":30,"IntervalBetweenConsultations":5,"Customized":false},{"Day":"Thursday","IsWorking":true,"TimeRange":{"StartTime":"08:00","EndTime":"17:00"},"BreakTime":null,"ConsultationDuration":30,"IntervalBetweenConsultations":5,"Customized":false},{"Day":"Friday","IsWorking":true,"TimeRange":{"StartTime":"08:00","EndTime":"17:00"},"BreakTime":null,"ConsultationDuration":30,"IntervalBetweenConsultations":5,"Customized":false},{"Day":"Saturday","IsWorking":false,"TimeRange":null,"BreakTime":null,"ConsultationDuration":null,"IntervalBetweenConsultations":null,"Customized":false},{"Day":"Sunday","IsWorking":false,"TimeRange":null,"BreakTime":null,"ConsultationDuration":null,"IntervalBetweenConsultations":null,"Customized":false}]	2026-02-04T00:00:00.0000000	2026-04-30T00:00:00.0000000	1	2026-02-04T06:14:15.8670264Z	2026-02-04T06:14:15.8670269Z
\.


--
-- Data for Name: SigtapProcedures; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."SigtapProcedures" ("Id", "Code", "Name", "Description", "Complexity", "GroupCode", "GroupName", "SubgroupCode", "SubgroupName", "AuthorizedCbosJson", "Value", "AllowsTelemedicine", "IsActive", "StartCompetency", "EndCompetency", "CreatedAt", "UpdatedAt") FROM stdin;
0135e2ce-3adc-4a05-bb71-41763243c24a	0301010064	Consulta m├®dica em aten├º├úo b├ísica	\N	0	03	Procedimentos Cl├¡nicos	\N	\N	\N	10.00	1	1	\N	\N	2026-02-01 17:51:59.877496+00	2026-02-01 17:51:59.877497+00
103fa5a7-e4db-4dee-abd4-5706e0204483	0301100012	Consulta de enfermagem	\N	0	03	Procedimentos Cl├¡nicos	\N	\N	\N	6.30	1	1	\N	\N	2026-02-01 17:51:59.878073+00	2026-02-01 17:51:59.878073+00
15fb50b9-4f84-422c-98a3-ae69d366db17	0301080070	Psicoterapia individual	\N	1	03	Procedimentos Cl├¡nicos	\N	\N	\N	22.42	1	1	\N	\N	2026-02-01 17:51:59.878109+00	2026-02-01 17:51:59.878109+00
217dcd52-67fb-48b4-bdc2-20969e8cc53d	0301070059	Consulta/atendimento de nutricionista	\N	0	03	Procedimentos Cl├¡nicos	\N	\N	\N	6.30	1	1	\N	\N	2026-02-01 17:51:59.878115+00	2026-02-01 17:51:59.878116+00
3988d737-d91f-4069-a6bc-20e79418dcc7	0301010188	Consulta de profissionais de n├¡vel superior na aten├º├úo especializada	\N	1	03	Procedimentos Cl├¡nicos	\N	\N	\N	6.30	1	1	\N	\N	2026-02-01 17:51:59.878058+00	2026-02-01 17:51:59.878058+00
64e0102c-b80c-474f-90b0-759e8091b235	0301080062	Atendimento em grupo em psicologia	\N	1	03	Procedimentos Cl├¡nicos	\N	\N	\N	4.67	1	1	\N	\N	2026-02-01 17:51:59.878075+00	2026-02-01 17:51:59.878075+00
7470bb81-57fb-42aa-9a18-555584aea1c1	0301050040	Atendimento de urg├¬ncia com observa├º├úo at├® 24h	\N	1	03	Procedimentos Cl├¡nicos	\N	\N	\N	35.00	0	1	\N	\N	2026-02-01 17:51:59.878068+00	2026-02-01 17:51:59.878068+00
7af94bc8-32d6-4546-a30f-101915238310	0301010129	Teleconsulta na aten├º├úo prim├íria	\N	0	03	Procedimentos Cl├¡nicos	\N	\N	\N	10.00	1	1	\N	\N	2026-02-01 17:51:59.878071+00	2026-02-01 17:51:59.878071+00
9f57ee1c-da66-4c3b-bb97-710cbbe39eb8	0301010145	Telemonitoramento de pacientes cr├┤nicos	\N	0	03	Procedimentos Cl├¡nicos	\N	\N	\N	5.00	1	1	\N	\N	2026-02-01 17:51:59.878072+00	2026-02-01 17:51:59.878073+00
c437736a-a2f7-43d1-904b-777bb744c6c9	0301010072	Consulta m├®dica em aten├º├úo especializada	\N	1	03	Procedimentos Cl├¡nicos	\N	\N	\N	10.00	1	1	\N	\N	2026-02-01 17:51:59.878054+00	2026-02-01 17:51:59.878054+00
d697455b-7df5-433d-830d-e0932b733d4c	0301010170	Consulta de profissionais de n├¡vel superior na aten├º├úo b├ísica	\N	0	03	Procedimentos Cl├¡nicos	\N	\N	\N	6.30	1	1	\N	\N	2026-02-01 17:51:59.878056+00	2026-02-01 17:51:59.878056+00
ec50dbb4-a2e7-4e6c-a664-efacd7d20864	0302050027	Atendimento fisioterap├¬utico em paciente neurofuncional	\N	1	03	Procedimentos Cl├¡nicos	\N	\N	\N	4.67	1	1	\N	\N	2026-02-01 17:51:59.878118+00	2026-02-01 17:51:59.878118+00
f0e9e0b3-e3e9-495a-a6de-0ffd02902476	0301070032	Consulta/atendimento de fonoaudi├│logo	\N	0	03	Procedimentos Cl├¡nicos	\N	\N	\N	6.30	1	1	\N	\N	2026-02-01 17:51:59.878119+00	2026-02-01 17:51:59.878119+00
f2fdff1a-cd72-41bd-b2e4-ff38acfcd805	0301080054	Atendimento individual em psicologia	\N	1	03	Procedimentos Cl├¡nicos	\N	\N	\N	22.42	1	1	\N	\N	2026-02-01 17:51:59.878074+00	2026-02-01 17:51:59.878074+00
fd94070f-ec82-4144-8add-19b42e824f26	0302050019	Atendimento fisioterap├¬utico nas altera├º├Áes motoras	\N	1	03	Procedimentos Cl├¡nicos	\N	\N	\N	4.67	1	1	\N	\N	2026-02-01 17:51:59.878116+00	2026-02-01 17:51:59.878116+00
fed98577-a8fc-4aa2-88a7-ff8a194258a4	0301010137	Teleconsulta na aten├º├úo especializada	\N	1	03	Procedimentos Cl├¡nicos	\N	\N	\N	10.00	1	1	\N	\N	2026-02-01 17:51:59.878072+00	2026-02-01 17:51:59.878072+00
\.


--
-- Data for Name: Specialties; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."Specialties" ("Id", "Name", "Description", "Status", "CustomFieldsJson", "CreatedAt", "UpdatedAt") FROM stdin;
48e0503f-d0a3-4702-b050-66d4c20b6d6d	Psiquiatria	Especialidade m├®dica dedicada ao diagn├│stico, tratamento e preven├º├úo de transtornos mentais, emocionais e comportamentais.	0	[\r\n        {"name":"Hist├│rico de Transtornos","type":"textarea","required":true,"description":"Descreva hist├│rico de transtornos mentais","order":1},\r\n        {"name":"Uso de Medica├º├úo Psiqui├ítrica","type":"radio","required":true,"description":"Faz uso de medica├º├úo psiqui├ítrica?","options":["Sim","N├úo"],"order":2},\r\n        {"name":"Medicamentos em Uso","type":"textarea","required":false,"description":"Liste os medicamentos psiqui├ítricos em uso","order":3},\r\n        {"name":"Idea├º├úo Suicida","type":"radio","required":true,"description":"Apresenta ou apresentou idea├º├úo suicida?","options":["Sim, atualmente","Sim, no passado","N├úo"],"order":4},\r\n        {"name":"Qualidade do Sono","type":"select","required":true,"description":"Como est├í a qualidade do sono?","options":["Boa","Regular","Ruim","Ins├┤nia"],"order":5},\r\n        {"name":"N├¡vel de Ansiedade (0-10)","type":"number","required":false,"description":"Avalie o n├¡vel de ansiedade de 0 a 10","order":6},\r\n        {"name":"Hist├│rico Familiar","type":"textarea","required":false,"description":"Hist├│rico familiar de transtornos mentais","order":7}\r\n    ]	2026-02-01T22:19:35.2572758Z	2026-02-01T22:19:35.2572768Z
3adebdb2-f9e3-476d-beba-3957684cd13f	Dermatologia	Especialidade m├®dica dedicada ao diagn├│stico e tratamento de doen├ºas da pele, cabelos, unhas e mucosas.	0	[\r\n        {"name":"Tipo de Pele","type":"select","required":true,"description":"Tipo de pele do paciente","options":["Normal","Seca","Oleosa","Mista","Sens├¡vel"],"order":1},\r\n        {"name":"Localiza├º├úo da Les├úo","type":"textarea","required":false,"description":"Descreva a localiza├º├úo das les├Áes","order":2},\r\n        {"name":"Tempo de Evolu├º├úo","type":"text","required":false,"description":"H├í quanto tempo apresenta as les├Áes?","order":3},\r\n        {"name":"Coceira","type":"radio","required":true,"description":"Apresenta coceira?","options":["Sim","N├úo"],"order":4},\r\n        {"name":"Exposi├º├úo Solar","type":"select","required":true,"description":"N├¡vel de exposi├º├úo solar","options":["Baixa","Moderada","Alta","Muito Alta"],"order":5},\r\n        {"name":"Uso de Protetor Solar","type":"radio","required":true,"description":"Usa protetor solar regularmente?","options":["Sim","N├úo","├Çs vezes"],"order":6},\r\n        {"name":"Alergias Conhecidas","type":"textarea","required":false,"description":"Liste alergias conhecidas","order":7}\r\n    ]	2026-02-01T22:19:35.3943600Z	2026-02-01T22:19:35.3943601Z
5fcc174a-32af-4fe3-ac71-e32646f3ef48	Pediatria	Especialidade m├®dica dedicada ao cuidado integral da sa├║de de crian├ºas e adolescentes, desde o nascimento at├® os 18 anos.	0	[\r\n        {"name":"Idade da Crian├ºa","type":"text","required":true,"description":"Idade (anos e meses)","order":1},\r\n        {"name":"Peso (kg)","type":"number","required":true,"description":"Peso em quilogramas","order":2},\r\n        {"name":"Altura (cm)","type":"number","required":true,"description":"Altura em cent├¡metros","order":3},\r\n        {"name":"Vacinas em Dia","type":"radio","required":true,"description":"Cart├úo de vacinas est├í em dia?","options":["Sim","N├úo","N├úo sei"],"order":4},\r\n        {"name":"Amamenta├º├úo","type":"select","required":false,"description":"Situa├º├úo da amamenta├º├úo","options":["N├úo se aplica","Exclusiva","Mista","N├úo amamenta"],"order":5},\r\n        {"name":"Desenvolvimento Motor","type":"select","required":true,"description":"Desenvolvimento motor adequado para idade?","options":["Adequado","Atrasado","Avan├ºado"],"order":6},\r\n        {"name":"Alergias Alimentares","type":"textarea","required":false,"description":"Liste alergias alimentares conhecidas","order":7},\r\n        {"name":"Frequenta Escola/Creche","type":"radio","required":false,"description":"A crian├ºa frequenta escola ou creche?","options":["Sim","N├úo"],"order":8}\r\n    ]	2026-02-01T22:19:35.4009618Z	2026-02-01T22:19:35.4009618Z
7f5a938e-3ae9-4f88-a984-1293fd5e1dcf	Cardiologia	Especialidade m├®dica dedicada ao diagn├│stico e tratamento de doen├ºas do cora├º├úo e do sistema circulat├│rio, incluindo hipertens├úo, insufici├¬ncia card├¡aca, arritmias e doen├ºas coronarianas.	0	[\r\n            {"name":"Hist├│rico de Infarto","type":"checkbox","required":true,"description":"Paciente j├í teve infarto do mioc├írdio?","order":1},\r\n            {"name":"Press├úo Arterial Sist├│lica","type":"number","required":true,"description":"Press├úo arterial sist├│lica em mmHg","defaultValue":"120","order":2},\r\n            {"name":"Press├úo Arterial Diast├│lica","type":"number","required":true,"description":"Press├úo arterial diast├│lica em mmHg","defaultValue":"80","order":3},\r\n            {"name":"Frequ├¬ncia Card├¡aca","type":"number","required":true,"description":"Batimentos por minuto em repouso","order":4},\r\n            {"name":"Uso de Marca-passo","type":"radio","required":true,"description":"Paciente faz uso de marca-passo?","options":["Sim","N├úo"],"order":5},\r\n            {"name":"Tipo de Dor Tor├ícica","type":"select","required":false,"description":"Caso apresente dor tor├ícica, qual o tipo?","options":["N├úo apresenta","Dor em aperto","Dor em queima├º├úo","Dor em pontada","Dor irradiada"],"order":6},\r\n            {"name":"Medicamentos Cardiovasculares","type":"textarea","required":false,"description":"Liste os medicamentos em uso para o cora├º├úo","order":7},\r\n            {"name":"Data ├Ültimo ECG","type":"date","required":false,"description":"Data do ├║ltimo eletrocardiograma realizado","order":8},\r\n            {"name":"Hist├│rico Familiar","type":"textarea","required":false,"description":"Hist├│rico familiar de doen├ºas cardiovasculares","order":9},\r\n            {"name":"N├¡vel de Colesterol","type":"select","required":false,"description":"├Ültimo exame de colesterol","options":["Normal","Borderline","Alto","N├úo sabe"],"order":10}\r\n        ]	2026-02-01 17:51:14.156514+00	2026-02-02T23:08:47.5084162Z
84ad7896-10b7-46c7-87f3-a3cac5bd2fd1	Neurologia	Especialidade m├®dica dedicada ao diagn├│stico e tratamento de doen├ºas do sistema nervoso central e perif├®rico.	0	[\r\n        {"name":"Tipo de Cefaleia","type":"select","required":false,"description":"Tipo de dor de cabe├ºa","options":["N├úo apresenta","Tensional","Enxaqueca","Em salvas","Outros"],"order":1},\r\n        {"name":"Frequ├¬ncia das Crises","type":"text","required":false,"description":"Quantas vezes por semana/m├¬s?","order":2},\r\n        {"name":"Hist├│rico de AVC","type":"radio","required":true,"description":"J├í teve AVC?","options":["Sim","N├úo"],"order":3},\r\n        {"name":"Convuls├Áes","type":"radio","required":true,"description":"Apresenta ou apresentou convuls├Áes?","options":["Sim","N├úo"],"order":4},\r\n        {"name":"Altera├º├Áes de Mem├│ria","type":"select","required":true,"description":"Apresenta altera├º├Áes de mem├│ria?","options":["N├úo","Leves","Moderadas","Graves"],"order":5},\r\n        {"name":"Formigamento/Dorm├¬ncia","type":"textarea","required":false,"description":"Descreva localiza├º├úo de formigamento ou dorm├¬ncia","order":6},\r\n        {"name":"Medicamentos Neurol├│gicos","type":"textarea","required":false,"description":"Liste medicamentos neurol├│gicos em uso","order":7},\r\n        {"name":"Exames de Imagem Recentes","type":"textarea","required":false,"description":"Resson├óncia, tomografia realizados recentemente?","order":8}\r\n    ]	2026-02-01T22:19:35.4090047Z	2026-02-01T22:19:35.4090047Z
\.


--
-- Data for Name: Users; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."Users" ("Id", "Email", "PasswordHash", "Name", "LastName", "Cpf", "Phone", "Avatar", "Role", "Status", "EmailVerified", "EmailVerificationToken", "EmailVerificationTokenExpiry", "PendingEmail", "PendingEmailToken", "PendingEmailTokenExpiry", "PasswordResetToken", "PasswordResetTokenExpiry", "RefreshToken", "RefreshTokenExpiry", "CreatedAt", "UpdatedAt") FROM stdin;
6f3a6731-435d-4f76-b725-42c993f2797c	med_gt@telecuidar.com	$2a$12$f7eWhItWM1dxRch0E6zvBujAf/EGfd8ozw7TswJi4RVKWJWNvjGya	Geraldo	Tadeu	90000000001	11900000001	\N	1	0	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-02-02T19:09:12.0117128Z	2026-02-02T19:09:12.0117132Z
a06cbf1d-2661-49ff-bbfb-0041b02dae5e	med_aj@telecuidar.com	$2a$12$f7eWhItWM1dxRch0E6zvBujAf/EGfd8ozw7TswJi4RVKWJWNvjGya	Ant├┤nio	Jorge	90000000000	11900000000	\N	1	0	1	\N	\N	\N	\N	\N	\N	\N	jlBu6ZRdeQ7M8tTh7cRjp5AZ8N1svS8VK7O0m7cpA6E=	2026-02-05T07:15:44.5095108Z	2026-02-02T19:09:11.9979995Z	2026-02-04T07:15:44.5125235Z
d61f6fb1-d2cd-4350-b242-003ac3a4464f	enf_do@telecuidar.com	$2a$12$f7eWhItWM1dxRch0E6zvBujAf/EGfd8ozw7TswJi4RVKWJWNvjGya	Daniela	Ochoa	90000000007	11900000007	\N	3	0	1	\N	\N	\N	\N	\N	\N	\N	42EpUYtCT4b/1T7TbmkhxbQL7yL9jtJ3emKw4cuWN0w=	2026-02-05T08:58:12.5493702Z	2026-02-02T19:09:12.1282545Z	2026-02-04T08:58:12.5495191Z
0b3b0ee6-1eec-4598-9d30-09442a923ae1	pac_do@telecuidar.com	$2a$12$f7eWhItWM1dxRch0E6zvBujAf/EGfd8ozw7TswJi4RVKWJWNvjGya	Daniela	Ochoa	90000000018	11900000018	\N	0	0	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-02-02T19:09:12.1581766Z	2026-02-02T19:09:12.1581770Z
5e764cc6-20b0-4c26-a342-0083beb4b229	pac_ca@telecuidar.com	$2a$12$f7eWhItWM1dxRch0E6zvBujAf/EGfd8ozw7TswJi4RVKWJWNvjGya	Cl├íudio	Amantino	90000000020	11900000020	\N	0	0	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-02-02T19:09:12.1588177Z	2026-02-02T19:09:12.1588180Z
8bbb6c58-b963-4f67-b001-c8fa41582afd	adm_ca@telecuidar.com	$2a$12$f7eWhItWM1dxRch0E6zvBujAf/EGfd8ozw7TswJi4RVKWJWNvjGya	Cl├íudio	Amantino	90000000014	11900000014	\N	2	0	1	\N	\N	\N	\N	\N	\N	\N	k7EkMCAilPMVyeWZQgnlUUetCueTMa9PVYiKU6UWEhk=	2026-02-05T06:12:44.8716911Z	2026-02-02T19:09:12.1382043Z	2026-02-04T06:12:44.8718707Z
6bf6f665-96ba-4aae-8a65-cfba0624bd49	pac_dc@telecuidar.com	$2a$12$f7eWhItWM1dxRch0E6zvBujAf/EGfd8ozw7TswJi4RVKWJWNvjGya	Daniel	Carrara	90000000019	11900000019	\N	0	0	1	\N	\N	\N	\N	\N	\N	\N	EKlnleEQfcPQWpmGJb7pumuQ5+ZppjqLLqxgnLlWiYk=	2026-02-05T06:14:56.2468294Z	2026-02-02T19:09:12.1585307Z	2026-02-04T06:14:56.2469659Z
f00d2c7c-cca1-4758-b64a-740042d900c5	rec_ma@telecuidar.com	$2a$12$f7eWhItWM1dxRch0E6zvBujAf/EGfd8ozw7TswJi4RVKWJWNvjGya	Maria	Atendimento	90000000015	11900000015	\N	4	0	1	\N	\N	\N	\N	\N	\N	\N	4gEwOyEwwq0nC2oCwQEJ6wjJQbnGFf9X0wRm+R0Th18=	2026-02-05T06:23:18.1525366Z	2026-02-02T19:09:12.1499981Z	2026-02-04T06:23:18.1526098Z
\.


--
-- Data for Name: WaitingLists; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."WaitingLists" ("Id", "AppointmentId", "PatientId", "ProfessionalId", "UnityId", "Position", "Priority", "CheckInTime", "CalledTime", "CallAttempts", "Status", "CreatedAt", "UpdatedAt", "IsSpontaneousDemand", "UrgencyLevel", "ChiefComplaint") FROM stdin;
\.


--
-- Data for Name: __EFMigrationsHistory; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public."__EFMigrationsHistory" ("MigrationId", "ProductVersion") FROM stdin;
20260102213207_InitialCreate	9.0.0
20260114115742_AddProfessionalCouncilsAndAuditFields	9.0.0
20260201000000_AddReceptionistAndWaitingList	9.0.0
20260202000000_AddSpontaneousDemandFields	9.0.0
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
-- Name: WaitingLists WaitingLists_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."WaitingLists"
    ADD CONSTRAINT "WaitingLists_pkey" PRIMARY KEY ("Id");


--
-- Name: IX_Appointments_AssistantId; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IX_Appointments_AssistantId" ON public."Appointments" USING btree ("AssistantId");


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
-- Name: IX_WaitingLists_AppointmentId; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IX_WaitingLists_AppointmentId" ON public."WaitingLists" USING btree ("AppointmentId");


--
-- Name: IX_WaitingLists_IsSpontaneousDemand; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IX_WaitingLists_IsSpontaneousDemand" ON public."WaitingLists" USING btree ("IsSpontaneousDemand");


--
-- Name: IX_WaitingLists_PatientId; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IX_WaitingLists_PatientId" ON public."WaitingLists" USING btree ("PatientId");


--
-- Name: IX_WaitingLists_ProfessionalId; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IX_WaitingLists_ProfessionalId" ON public."WaitingLists" USING btree ("ProfessionalId");


--
-- Name: IX_WaitingLists_Status_Position; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IX_WaitingLists_Status_Position" ON public."WaitingLists" USING btree ("Status", "Position");


--
-- Name: Appointments FK_Appointments_Specialties_SpecialtyId; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Appointments"
    ADD CONSTRAINT "FK_Appointments_Specialties_SpecialtyId" FOREIGN KEY ("SpecialtyId") REFERENCES public."Specialties"("Id") ON DELETE RESTRICT;


--
-- Name: Appointments FK_Appointments_Users_AssistantId; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Appointments"
    ADD CONSTRAINT "FK_Appointments_Users_AssistantId" FOREIGN KEY ("AssistantId") REFERENCES public."Users"("Id") ON DELETE SET NULL;


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
-- Name: WaitingLists FK_WaitingLists_Appointments_AppointmentId; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."WaitingLists"
    ADD CONSTRAINT "FK_WaitingLists_Appointments_AppointmentId" FOREIGN KEY ("AppointmentId") REFERENCES public."Appointments"("Id") ON DELETE CASCADE;


--
-- Name: WaitingLists FK_WaitingLists_Users_PatientId; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."WaitingLists"
    ADD CONSTRAINT "FK_WaitingLists_Users_PatientId" FOREIGN KEY ("PatientId") REFERENCES public."Users"("Id") ON DELETE RESTRICT;


--
-- Name: WaitingLists FK_WaitingLists_Users_ProfessionalId; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."WaitingLists"
    ADD CONSTRAINT "FK_WaitingLists_Users_ProfessionalId" FOREIGN KEY ("ProfessionalId") REFERENCES public."Users"("Id") ON DELETE RESTRICT;


--
-- PostgreSQL database dump complete
--

\unrestrict duTE1PPr5bDNhk5EyG8Lwv5AeVskfLIObL6MWUBhvi0M7jEQVhD1tFvf7GCJvfn

