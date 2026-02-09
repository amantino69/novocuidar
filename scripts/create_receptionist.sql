-- Criar recepcionista se não existir
INSERT INTO "Users" ("Id", "Name", "LastName", "Email", "Cpf", "Phone", "PasswordHash", "Role", "Status", "EmailVerified", "CreatedAt", "UpdatedAt")
SELECT 
    gen_random_uuid(),
    'Maria',
    'Atendimento',
    'rec_ma@telecuidar.com',
    '88888888888',
    '62988888888',
    (SELECT "PasswordHash" FROM "Users" LIMIT 1),
    4,
    1,
    1,
    NOW(),
    NOW()
WHERE NOT EXISTS (SELECT 1 FROM "Users" WHERE "Email" = 'rec_ma@telecuidar.com');
