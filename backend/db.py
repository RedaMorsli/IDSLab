import duckdb
import os

DB_PATH = os.path.join(os.environ.get("DB_DIR", "."), "index.db")

def init_database(db_path=DB_PATH):
    execute("""
        CREATE TABLE IF NOT EXISTS Clusters (
            cluster_id INTEGER PRIMARY KEY,
            cluster_name TEXT NOT NULL,
            config_json TEXT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
            
        CREATE SEQUENCE IF NOT EXISTS seq_cluster_id START 1;

        CREATE TABLE IF NOT EXISTS Applications (
            app_id INTEGER PRIMARY KEY,
            app_name TEXT NOT NULL,
            cluster_name TEXT NOT NULL,
            namespaces TEXT,
            labels TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
            
        CREATE SEQUENCE IF NOT EXISTS seq_app_id START 1;
            
        CREATE TABLE IF NOT EXISTS WebApplications (
            app_id INTEGER PRIMARY KEY,
            app_name TEXT NOT NULL,
            address TEXT NOT NULL,
            port INTEGER,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
            
        CREATE SEQUENCE IF NOT EXISTS seq_web_app_id START 1;
            
        CREATE TABLE IF NOT EXISTS Repositories (
            repository_id INTEGER PRIMARY KEY,
            repository_name TEXT NOT NULL,
            s3_bucket TEXT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
            
        CREATE SEQUENCE IF NOT EXISTS seq_repository_id START 1;
            
        CREATE TABLE IF NOT EXISTS CollectorFilters (
            filter_id INTEGER PRIMARY KEY,
            filter_name TEXT NOT NULL,
            scope_expressions TEXT NOT NULL,
            events TEXT NOT NULL,
            metrics TEXT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
            
        CREATE SEQUENCE IF NOT EXISTS seq_filter_id START 1;

        CREATE TABLE IF NOT EXISTS Collectors (
            collector_id INTEGER PRIMARY KEY,
            collector_name TEXT NOT NULL,
            cluster_id INTEGER,
            filter_id INTEGER,
            repository_id INTEGER,
            start_time TIMESTAMP,
            finish_time TIMESTAMP,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );

        CREATE SEQUENCE IF NOT EXISTS seq_collector_id START 1;
            
        
        CREATE SEQUENCE IF NOT EXISTS seq_dataset_id START 1;

        CREATE TABLE IF NOT EXISTS Datasets (
            dataset_id INTEGER PRIMARY KEY DEFAULT nextval('seq_dataset_id'),
            dataset_name TEXT NOT NULL,
            dataset_graph TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );

        """)


def execute(sql: str, params=None):
    con = duckdb.connect(DB_PATH)
    con.execute(sql, params)
    # print("Executed: " + sql)
    con.close()

def execute_fetch_all(sql: str, params=None) -> list:
    con = duckdb.connect(DB_PATH)
    result = con.execute(sql, params).fetchall()
    # print("Executed: " + sql)
    con.close()
    return result

def get_seq_last_val(seq_name: str) -> int:
   return get_seq_current_val(seq_name) - 1
    
def get_seq_current_val(seq_name: str) -> int:
    con = duckdb.connect(DB_PATH)
    try:
        return con.execute(f"SELECT currval('{seq_name}');").fetchone()[0]
    except Exception as e:
        msg = str(e)
        if 'currval: sequence is not yet defined in this session' in msg or 'sequence is not yet defined' in msg:
            # initialize session sequence state
            con.execute(f"SELECT nextval('{seq_name}');")
            return con.execute(f"SELECT currval('{seq_name}');").fetchone()[0]
        # Unknown error -- re-raise
        raise
    finally:
        con.close()
