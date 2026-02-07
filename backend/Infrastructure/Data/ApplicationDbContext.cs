using Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Storage.ValueConversion;

namespace Infrastructure.Data;

public class ApplicationDbContext : DbContext
{
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
        : base(options)
    {
    }

    public DbSet<User> Users { get; set; }
    public DbSet<PatientProfile> PatientProfiles { get; set; }
    public DbSet<ProfessionalProfile> ProfessionalProfiles { get; set; }
    public DbSet<Specialty> Specialties { get; set; }
    public DbSet<Appointment> Appointments { get; set; }
    public DbSet<Notification> Notifications { get; set; }
    public DbSet<Schedule> Schedules { get; set; }
    public DbSet<AuditLog> AuditLogs { get; set; }
    public DbSet<Attachment> Attachments { get; set; }
    public DbSet<Invite> Invites { get; set; }
    public DbSet<ScheduleBlock> ScheduleBlocks { get; set; }
    public DbSet<Prescription> Prescriptions { get; set; }
    public DbSet<MedicalCertificate> MedicalCertificates { get; set; }
    public DbSet<DigitalCertificate> DigitalCertificates { get; set; }
    public DbSet<ExamRequest> ExamRequests { get; set; }
    public DbSet<MedicalReport> MedicalReports { get; set; }
    
    // Tabelas de referência para prontuário e licitações
    public DbSet<ProfessionalCouncil> ProfessionalCouncils { get; set; }
    public DbSet<CboOccupation> CboOccupations { get; set; }
    public DbSet<SigtapProcedure> SigtapProcedures { get; set; }
    
    // Gerenciamento de fila de espera (NOVO)
    public DbSet<WaitingList> WaitingLists { get; set; }
    
    // Gestão Municipal (Regulação)
    public DbSet<Municipality> Municipalities { get; set; }
    public DbSet<HealthFacility> HealthFacilities { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // Conversores para compatibilidade com schema legado do SQLite (IDs como TEXT)
        var boolConverter = new BoolToZeroOneConverter<int>();
        var nullableBoolConverter = new ValueConverter<bool?, int?>(
            v => v.HasValue ? (v.Value ? 1 : 0) : (int?)null,
            v => v.HasValue ? v.Value == 1 : (bool?)null);

        var guidConverter = new ValueConverter<Guid, string>(
            v => v.ToString(),
            v => Guid.Parse(v));

        var nullableGuidConverter = new ValueConverter<Guid?, string?>(
            v => v.HasValue ? v.Value.ToString() : null,
            v => string.IsNullOrWhiteSpace(v) ? (Guid?)null : Guid.Parse(v));

        var dateTimeConverter = new ValueConverter<DateTime, string>(
            v => v.ToString("O"),
            v => DateTime.Parse(v, null, System.Globalization.DateTimeStyles.RoundtripKind));

        var nullableDateTimeConverter = new ValueConverter<DateTime?, string?>(
            v => v.HasValue ? v.Value.ToString("O") : null,
            v => string.IsNullOrWhiteSpace(v) ? (DateTime?)null : DateTime.Parse(v, null, System.Globalization.DateTimeStyles.RoundtripKind));

        var timeSpanConverter = new ValueConverter<TimeSpan, string>(
            v => v.ToString("c"),
            v => TimeSpan.Parse(v));

        var nullableTimeSpanConverter = new ValueConverter<TimeSpan?, string?>(
            v => v.HasValue ? v.Value.ToString("c") : null,
            v => string.IsNullOrWhiteSpace(v) ? (TimeSpan?)null : TimeSpan.Parse(v));

        foreach (var entityType in modelBuilder.Model.GetEntityTypes())
        {
            foreach (var property in entityType.GetProperties())
            {
                if (property.ClrType == typeof(bool))
                {
                    property.SetValueConverter(boolConverter);
                }
                else if (property.ClrType == typeof(bool?))
                {
                    property.SetValueConverter(nullableBoolConverter);
                }
                else if (property.ClrType == typeof(Guid))
                {
                    property.SetValueConverter(guidConverter);
                }
                else if (property.ClrType == typeof(Guid?))
                {
                    property.SetValueConverter(nullableGuidConverter);
                }
                else if (property.ClrType == typeof(DateTime))
                {
                    property.SetValueConverter(dateTimeConverter);
                }
                else if (property.ClrType == typeof(DateTime?))
                {
                    property.SetValueConverter(nullableDateTimeConverter);
                }
                else if (property.ClrType == typeof(TimeSpan))
                {
                    property.SetValueConverter(timeSpanConverter);
                }
                else if (property.ClrType == typeof(TimeSpan?))
                {
                    property.SetValueConverter(nullableTimeSpanConverter);
                }
            }
        }

        // User Configuration
        modelBuilder.Entity<User>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => e.Email).IsUnique();
            entity.HasIndex(e => e.Cpf).IsUnique();
            entity.HasIndex(e => e.Phone).IsUnique();
            entity.Property(e => e.Email).IsRequired().HasMaxLength(255);
            entity.Property(e => e.PasswordHash).IsRequired();
            entity.Property(e => e.Name).IsRequired().HasMaxLength(100);
            entity.Property(e => e.LastName).IsRequired().HasMaxLength(100);
            entity.Property(e => e.Cpf).IsRequired().HasMaxLength(14);
            entity.Property(e => e.Phone).HasMaxLength(20);
            entity.Property(e => e.Avatar).HasMaxLength(500);

            entity.HasMany(e => e.AppointmentsAsPatient)
                .WithOne(a => a.Patient)
                .HasForeignKey(a => a.PatientId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasMany(e => e.AppointmentsAsProfessional)
                .WithOne(a => a.Professional)
                .HasForeignKey(a => a.ProfessionalId)
                .OnDelete(DeleteBehavior.Restrict);
                
            // Relacionamento 1:1 com PatientProfile
            entity.HasOne(e => e.PatientProfile)
                .WithOne(p => p.User)
                .HasForeignKey<PatientProfile>(p => p.UserId)
                .OnDelete(DeleteBehavior.Cascade);
                
            // Relacionamento 1:1 com ProfessionalProfile
            entity.HasOne(e => e.ProfessionalProfile)
                .WithOne(p => p.User)
                .HasForeignKey<ProfessionalProfile>(p => p.UserId)
                .OnDelete(DeleteBehavior.Cascade);
            
            // Relacionamento N:1 com Municipality (para Reguladores)
            entity.HasOne(e => e.Municipio)
                .WithMany(m => m.Reguladores)
                .HasForeignKey(e => e.MunicipioId)
                .OnDelete(DeleteBehavior.SetNull);
            
            entity.HasIndex(e => e.MunicipioId);
        });
        
        // PatientProfile Configuration
        modelBuilder.Entity<PatientProfile>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => e.UserId).IsUnique();
            entity.HasIndex(e => e.Cns);
            entity.HasIndex(e => e.ESusId);
            entity.HasIndex(e => e.MunicipioId);
            entity.HasIndex(e => e.UnidadeAdscritaId);
            entity.Property(e => e.Cns).HasMaxLength(15);
            entity.Property(e => e.SocialName).HasMaxLength(200);
            entity.Property(e => e.ESusId).HasMaxLength(50);
            entity.Property(e => e.Gender).HasMaxLength(20);
            entity.Property(e => e.MotherName).HasMaxLength(200);
            entity.Property(e => e.FatherName).HasMaxLength(200);
            entity.Property(e => e.Nationality).HasMaxLength(100);
            entity.Property(e => e.RacaCor).HasMaxLength(50);
            entity.Property(e => e.ZipCode).HasMaxLength(10);
            entity.Property(e => e.Logradouro).HasMaxLength(300);
            entity.Property(e => e.Numero).HasMaxLength(20);
            entity.Property(e => e.Complemento).HasMaxLength(100);
            entity.Property(e => e.Bairro).HasMaxLength(100);
            entity.Property(e => e.Address).HasMaxLength(500);
            entity.Property(e => e.City).HasMaxLength(100);
            entity.Property(e => e.State).HasMaxLength(2);
            
            // Relacionamento com Município
            entity.HasOne(e => e.Municipio)
                .WithMany(m => m.Patients)
                .HasForeignKey(e => e.MunicipioId)
                .OnDelete(DeleteBehavior.SetNull);
            
            // Relacionamento com Unidade de Saúde Adscrita
            entity.HasOne(e => e.UnidadeAdscrita)
                .WithMany(u => u.PacientesAdscritos)
                .HasForeignKey(e => e.UnidadeAdscritaId)
                .OnDelete(DeleteBehavior.SetNull);
        });
        
        // Municipality Configuration
        modelBuilder.Entity<Municipality>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => e.CodigoIBGE).IsUnique();
            entity.Property(e => e.CodigoIBGE).IsRequired().HasMaxLength(7);
            entity.Property(e => e.Nome).IsRequired().HasMaxLength(200);
            entity.Property(e => e.UF).IsRequired().HasMaxLength(2);
        });
        
        // HealthFacility Configuration
        modelBuilder.Entity<HealthFacility>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => e.CodigoCNES).IsUnique();
            entity.HasIndex(e => e.MunicipioId);
            entity.Property(e => e.CodigoCNES).IsRequired().HasMaxLength(7);
            entity.Property(e => e.NomeFantasia).IsRequired().HasMaxLength(300);
            entity.Property(e => e.RazaoSocial).HasMaxLength(300);
            entity.Property(e => e.TipoEstabelecimento).HasMaxLength(10);
            entity.Property(e => e.TipoEstabelecimentoDescricao).HasMaxLength(200);
            entity.Property(e => e.CNPJ).HasMaxLength(18);
            entity.Property(e => e.CEP).HasMaxLength(10);
            entity.Property(e => e.Logradouro).HasMaxLength(300);
            entity.Property(e => e.Numero).HasMaxLength(20);
            entity.Property(e => e.Complemento).HasMaxLength(100);
            entity.Property(e => e.Bairro).HasMaxLength(100);
            entity.Property(e => e.Telefone).HasMaxLength(20);
            entity.Property(e => e.Email).HasMaxLength(200);
            
            // Relacionamento com Município
            entity.HasOne(e => e.Municipio)
                .WithMany(m => m.HealthFacilities)
                .HasForeignKey(e => e.MunicipioId)
                .OnDelete(DeleteBehavior.Cascade);
        });
        
        // ProfessionalProfile Configuration
        modelBuilder.Entity<ProfessionalProfile>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => e.UserId).IsUnique();
            entity.HasIndex(e => e.Crm);
            entity.HasIndex(e => e.CouncilRegistration);
            entity.Property(e => e.Crm).HasMaxLength(20);
            entity.Property(e => e.CouncilRegistration).HasMaxLength(20);
            entity.Property(e => e.CouncilState).HasMaxLength(2);
            entity.Property(e => e.Cbo).HasMaxLength(10);
            entity.Property(e => e.Gender).HasMaxLength(20);
            entity.Property(e => e.Nationality).HasMaxLength(100);
            entity.Property(e => e.ZipCode).HasMaxLength(10);
            entity.Property(e => e.Address).HasMaxLength(500);
            entity.Property(e => e.City).HasMaxLength(100);
            entity.Property(e => e.State).HasMaxLength(2);
            
            // Relacionamento com Specialty
            entity.HasOne(e => e.Specialty)
                .WithMany(s => s.Professionals)
                .HasForeignKey(e => e.SpecialtyId)
                .OnDelete(DeleteBehavior.SetNull);
            
            // Relacionamento com ProfessionalCouncil
            entity.HasOne(e => e.Council)
                .WithMany(c => c.Professionals)
                .HasForeignKey(e => e.CouncilId)
                .OnDelete(DeleteBehavior.SetNull);
            
            // Relacionamento com CboOccupation
            entity.HasOne(e => e.CboOccupation)
                .WithMany(c => c.Professionals)
                .HasForeignKey(e => e.CboOccupationId)
                .OnDelete(DeleteBehavior.SetNull);
        });

        // Specialty Configuration
        modelBuilder.Entity<Specialty>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Name).IsRequired().HasMaxLength(200);
            entity.Property(e => e.Description).IsRequired().HasMaxLength(1000);
        });

        // Appointment Configuration
        modelBuilder.Entity<Appointment>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Observation).HasMaxLength(2000);
            entity.Property(e => e.MeetLink).HasMaxLength(500);

            // ÍNDICES PARA PERFORMANCE
            entity.HasIndex(e => e.PatientId);
            entity.HasIndex(e => e.ProfessionalId);
            entity.HasIndex(e => e.Date);
            entity.HasIndex(e => e.Status);
            entity.HasIndex(e => new { e.Date, e.Status }); // Índice composto para queries comuns

            entity.HasOne(e => e.Specialty)
                .WithMany(s => s.Appointments)
                .HasForeignKey(e => e.SpecialtyId)
                .OnDelete(DeleteBehavior.Restrict);
            
            // Relacionamento com Assistant (Enfermeira) - NOVO
            entity.HasOne(e => e.Assistant)
                .WithMany(u => u.AppointmentsAsAssistant)
                .HasForeignKey(e => e.AssistantId)
                .OnDelete(DeleteBehavior.SetNull);
        });

        // Notification Configuration
        modelBuilder.Entity<Notification>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Title).IsRequired().HasMaxLength(200);
            entity.Property(e => e.Message).IsRequired().HasMaxLength(1000);
            entity.Property(e => e.Type).IsRequired().HasMaxLength(50);
            entity.Property(e => e.Link).HasMaxLength(500);

            entity.HasOne(e => e.User)
                .WithMany(u => u.Notifications)
                .HasForeignKey(e => e.UserId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // Schedule Configuration
        modelBuilder.Entity<Schedule>(entity =>
        {
            entity.HasKey(e => e.Id);
            
            // ÍNDICES PARA PERFORMANCE
            entity.HasIndex(e => e.IsActive);
            entity.HasIndex(e => e.ProfessionalId);

            entity.HasOne(e => e.Professional)
                .WithMany(u => u.Schedules)
                .HasForeignKey(e => e.ProfessionalId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // AuditLog Configuration
        modelBuilder.Entity<AuditLog>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Action).IsRequired().HasMaxLength(100);
            entity.Property(e => e.EntityType).IsRequired().HasMaxLength(100);
            entity.Property(e => e.IpAddress).HasMaxLength(45);
            entity.Property(e => e.PatientCpf).HasMaxLength(14);
            entity.Property(e => e.DataCategory).HasMaxLength(50);
            entity.Property(e => e.AccessReason).HasMaxLength(500);
            entity.HasIndex(e => e.PatientId);
            entity.HasIndex(e => e.PatientCpf);
            entity.HasIndex(e => e.Action);
            entity.HasIndex(e => e.CreatedAt);

            entity.HasOne(e => e.User)
                .WithMany(u => u.AuditLogs)
                .HasForeignKey(e => e.UserId)
                .OnDelete(DeleteBehavior.SetNull);
            
            entity.HasOne(e => e.Patient)
                .WithMany()
                .HasForeignKey(e => e.PatientId)
                .OnDelete(DeleteBehavior.SetNull);
        });

        // Attachment Configuration
        modelBuilder.Entity<Attachment>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Title).IsRequired().HasMaxLength(200);
            entity.Property(e => e.FileName).IsRequired().HasMaxLength(255);
            entity.Property(e => e.FilePath).IsRequired().HasMaxLength(1000);
            entity.Property(e => e.FileType).IsRequired().HasMaxLength(100);

            entity.HasOne(e => e.Appointment)
                .WithMany(a => a.Attachments)
                .HasForeignKey(e => e.AppointmentId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // Invite Configuration
        modelBuilder.Entity<Invite>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => e.Token).IsUnique();
            entity.HasIndex(e => e.Email);
            entity.Property(e => e.Email).HasMaxLength(255); // Email não é mais obrigatório para links genéricos
            entity.Property(e => e.Token).IsRequired().HasMaxLength(50);
            
            entity.HasOne(e => e.CreatedByUser)
                .WithMany()
                .HasForeignKey(e => e.CreatedBy)
                .OnDelete(DeleteBehavior.Restrict);
        });

        // ScheduleBlock Configuration
        modelBuilder.Entity<ScheduleBlock>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Reason).IsRequired().HasMaxLength(500);
            entity.Property(e => e.RejectionReason).HasMaxLength(500);

            entity.HasOne(e => e.Professional)
                .WithMany(u => u.ScheduleBlocks)
                .HasForeignKey(e => e.ProfessionalId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(e => e.Approver)
                .WithMany()
                .HasForeignKey(e => e.ApprovedBy)
                .OnDelete(DeleteBehavior.SetNull);
        });

        // Prescription Configuration
        modelBuilder.Entity<Prescription>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.ItemsJson).IsRequired();
            entity.Property(e => e.DigitalSignature).HasMaxLength(10000);
            entity.Property(e => e.CertificateThumbprint).HasMaxLength(100);
            entity.Property(e => e.CertificateSubject).HasMaxLength(500);
            entity.Property(e => e.DocumentHash).HasMaxLength(100);
            entity.HasIndex(e => e.DocumentHash);

            entity.HasOne(e => e.Appointment)
                .WithMany()
                .HasForeignKey(e => e.AppointmentId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(e => e.Professional)
                .WithMany()
                .HasForeignKey(e => e.ProfessionalId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(e => e.Patient)
                .WithMany()
                .HasForeignKey(e => e.PatientId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        // MedicalCertificate Configuration
        modelBuilder.Entity<MedicalCertificate>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Tipo).IsRequired();
            entity.Property(e => e.Conteudo).IsRequired();
            entity.Property(e => e.Cid).HasMaxLength(20);
            entity.Property(e => e.DigitalSignature).HasMaxLength(10000);
            entity.Property(e => e.CertificateThumbprint).HasMaxLength(100);
            entity.Property(e => e.CertificateSubject).HasMaxLength(500);
            entity.Property(e => e.DocumentHash).HasMaxLength(100);
            entity.HasIndex(e => e.DocumentHash);
            entity.HasIndex(e => e.AppointmentId);

            entity.HasOne(e => e.Appointment)
                .WithMany()
                .HasForeignKey(e => e.AppointmentId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(e => e.Professional)
                .WithMany()
                .HasForeignKey(e => e.ProfessionalId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(e => e.Patient)
                .WithMany()
                .HasForeignKey(e => e.PatientId)
                .OnDelete(DeleteBehavior.Restrict);
        });
        
        // DigitalCertificate Configuration
        modelBuilder.Entity<DigitalCertificate>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.DisplayName).IsRequired().HasMaxLength(200);
            entity.Property(e => e.Subject).IsRequired().HasMaxLength(500);
            entity.Property(e => e.Issuer).IsRequired().HasMaxLength(500);
            entity.Property(e => e.Thumbprint).IsRequired().HasMaxLength(100);
            entity.Property(e => e.CpfFromCertificate).HasMaxLength(14);
            entity.Property(e => e.NameFromCertificate).HasMaxLength(300);
            entity.Property(e => e.EncryptedPfxBase64).IsRequired();
            entity.Property(e => e.EncryptionIV).IsRequired().HasMaxLength(100);
            entity.HasIndex(e => e.UserId);
            entity.HasIndex(e => e.Thumbprint);
            
            entity.HasOne(e => e.User)
                .WithMany(u => u.DigitalCertificates)
                .HasForeignKey(e => e.UserId)
                .OnDelete(DeleteBehavior.Cascade);
        });
        
        // ExamRequest Configuration
        modelBuilder.Entity<ExamRequest>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.NomeExame).IsRequired().HasMaxLength(500);
            entity.Property(e => e.CodigoExame).HasMaxLength(50);
            entity.Property(e => e.Categoria).IsRequired();
            entity.Property(e => e.Prioridade).IsRequired();
            entity.Property(e => e.IndicacaoClinica).IsRequired().HasMaxLength(2000);
            entity.Property(e => e.HipoteseDiagnostica).HasMaxLength(500);
            entity.Property(e => e.Cid).HasMaxLength(20);
            entity.Property(e => e.Observacoes).HasMaxLength(2000);
            entity.Property(e => e.InstrucoesPreparo).HasMaxLength(2000);
            entity.Property(e => e.DigitalSignature).HasMaxLength(10000);
            entity.Property(e => e.CertificateThumbprint).HasMaxLength(100);
            entity.Property(e => e.CertificateSubject).HasMaxLength(500);
            entity.Property(e => e.DocumentHash).HasMaxLength(100);
            entity.HasIndex(e => e.DocumentHash);
            entity.HasIndex(e => e.AppointmentId);

            entity.HasOne(e => e.Appointment)
                .WithMany()
                .HasForeignKey(e => e.AppointmentId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(e => e.Professional)
                .WithMany()
                .HasForeignKey(e => e.ProfessionalId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(e => e.Patient)
                .WithMany()
                .HasForeignKey(e => e.PatientId)
                .OnDelete(DeleteBehavior.Restrict);
        });
        
        // MedicalReport Configuration
        modelBuilder.Entity<MedicalReport>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Tipo).IsRequired();
            entity.Property(e => e.Titulo).IsRequired().HasMaxLength(500);
            entity.Property(e => e.HistoricoClinico).HasMaxLength(5000);
            entity.Property(e => e.ExameFisico).HasMaxLength(5000);
            entity.Property(e => e.ExamesComplementares).HasMaxLength(5000);
            entity.Property(e => e.HipoteseDiagnostica).HasMaxLength(500);
            entity.Property(e => e.Cid).HasMaxLength(20);
            entity.Property(e => e.Conclusao).IsRequired().HasMaxLength(5000);
            entity.Property(e => e.Recomendacoes).HasMaxLength(3000);
            entity.Property(e => e.Observacoes).HasMaxLength(2000);
            entity.Property(e => e.DigitalSignature).HasMaxLength(10000);
            entity.Property(e => e.CertificateThumbprint).HasMaxLength(100);
            entity.Property(e => e.CertificateSubject).HasMaxLength(500);
            entity.Property(e => e.DocumentHash).HasMaxLength(100);
            entity.HasIndex(e => e.DocumentHash);
            entity.HasIndex(e => e.AppointmentId);

            entity.HasOne(e => e.Appointment)
                .WithMany()
                .HasForeignKey(e => e.AppointmentId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(e => e.Professional)
                .WithMany()
                .HasForeignKey(e => e.ProfessionalId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(e => e.Patient)
                .WithMany()
                .HasForeignKey(e => e.PatientId)
                .OnDelete(DeleteBehavior.Restrict);
        });
        
        // ============================================
        // Tabelas de Referência (Conselhos, CBO, SIGTAP)
        // ============================================
        
        // ProfessionalCouncil Configuration
        modelBuilder.Entity<ProfessionalCouncil>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => e.Acronym).IsUnique();
            entity.Property(e => e.Acronym).IsRequired().HasMaxLength(20);
            entity.Property(e => e.Name).IsRequired().HasMaxLength(200);
            entity.Property(e => e.Category).IsRequired().HasMaxLength(100);
        });
        
        // CboOccupation Configuration
        modelBuilder.Entity<CboOccupation>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => e.Code).IsUnique();
            entity.Property(e => e.Code).IsRequired().HasMaxLength(10);
            entity.Property(e => e.Name).IsRequired().HasMaxLength(500);
            entity.Property(e => e.Family).HasMaxLength(200);
            entity.Property(e => e.Subgroup).HasMaxLength(200);
        });
        
        // SigtapProcedure Configuration
        modelBuilder.Entity<SigtapProcedure>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => e.Code).IsUnique();
            entity.Property(e => e.Code).IsRequired().HasMaxLength(20);
            entity.Property(e => e.Name).IsRequired().HasMaxLength(500);
            entity.Property(e => e.Description).HasMaxLength(2000);
            entity.Property(e => e.GroupCode).HasMaxLength(10);
            entity.Property(e => e.GroupName).HasMaxLength(200);
            entity.Property(e => e.SubgroupCode).HasMaxLength(10);
            entity.Property(e => e.SubgroupName).HasMaxLength(200);
            entity.Property(e => e.StartCompetency).HasMaxLength(6);
            entity.Property(e => e.EndCompetency).HasMaxLength(6);
            entity.Property(e => e.Value).HasPrecision(18, 2);
        });

        // WaitingList Configuration (NOVO)
        modelBuilder.Entity<WaitingList>(entity =>
        {
            entity.HasKey(e => e.Id);
            
            // Relacionamento com Appointment (1:1)
            entity.HasOne(e => e.Appointment)
                .WithOne(a => a.WaitingList)
                .HasForeignKey<WaitingList>(e => e.AppointmentId)
                .OnDelete(DeleteBehavior.Cascade);
            
            // Relacionamento com Patient
            entity.HasOne(e => e.Patient)
                .WithMany(u => u.WaitingListsAsPatient)
                .HasForeignKey(e => e.PatientId)
                .OnDelete(DeleteBehavior.Restrict);
            
            // Relacionamento com Professional
            entity.HasOne(e => e.Professional)
                .WithMany(u => u.WaitingListsAsProfessional)
                .HasForeignKey(e => e.ProfessionalId)
                .OnDelete(DeleteBehavior.Restrict);
            
            // Índices para otimização de queries
            entity.HasIndex(e => new { e.Status, e.Position });
            entity.HasIndex(e => e.CheckInTime);
        });
    }

    public override Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        var entries = ChangeTracker.Entries()
            .Where(e => e.State == EntityState.Modified);

        foreach (var entry in entries)
        {
            if (entry.Entity is Domain.Common.BaseEntity entity)
            {
                entity.UpdatedAt = DateTime.UtcNow;
            }
        }

        return base.SaveChangesAsync(cancellationToken);
    }
}
