#!/usr/bin/env python3
import psycopg2

try:
    conn = psycopg2.connect(
        dbname='telecuidar',
        user='postgres',
        host='localhost',
        password='postgres'
    )
    cur = conn.cursor()
    
    # Delete POC users
    cur.execute('DELETE FROM "Users" WHERE "Email" LIKE \'%@telecuidar.com%\'')
    deleted = cur.rowcount
    conn.commit()
    
    print(f'✅ {deleted} usuários POC deletados')
    print('🔄 Execute o backend novamente para rodar o seeder')
    
    conn.close()
except Exception as e:
    print(f'❌ Erro: {e}')
    print('📝 Verifique se PostgreSQL está rodando em localhost:5432')
