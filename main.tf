terraform {
  backend "s3" {
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    region                      = "us-west-002"

    use_path_style = true
    key            = "terraform-scaleway-postgres-ente.tfstate"
  }
}

# Get project information
data "scaleway_account_project" "ente" {
  name = "Ente"
}

# Create new application
resource "scaleway_iam_application" "ente" {
  name = "ente"
}

# Create policy to restrict access
resource "scaleway_iam_policy" "db_access" {
  name           = "ente-db-access"
  description    = "Allow access to database"
  application_id = scaleway_iam_application.ente.id
  rule {
    project_ids          = [data.scaleway_account_project.ente.project_id]
    permission_set_names = ["ServerlessSQLDatabaseReadWrite"]
  }
}

# Create API key to access database
resource "scaleway_iam_api_key" "ente_db_access" {
  application_id = scaleway_iam_application.ente.id
}

# Create Serverless SQL Database
resource "scaleway_sdb_sql_database" "ente" {
  name    = "ente"
  min_cpu = 0
  max_cpu = 2
}

# Write secret containing connection details
resource "vault_kv_secret" "ente_scaleway" {
  path = "kv/ente/scaleway/ente-scaleway-postgres"
  data_json = jsonencode({
    host = trimsuffix(
      trimprefix(scaleway_sdb_sql_database.ente.endpoint, "postgres://"),
      ":5432/${scaleway_sdb_sql_database.ente.name}?sslmode=require"
    )
    port     = 5432
    name     = scaleway_sdb_sql_database.ente.name
    sslmode  = "verify-full"
    user     = scaleway_iam_application.ente.id
    password = scaleway_iam_api_key.ente_db_access.secret_key
  })
}

# Prepare Vault policy document
data "vault_policy_document" "ente_scaleway_postgres" {
  rule {
    path         = vault_kv_secret.ente_scaleway.path
    capabilities = ["read"]
    description  = "Allow read-only access to Scaleway API key"
  }
}

# Create Vault policy for accessing B2 application keys
resource "vault_policy" "ente_scaleway_postgres" {
  name   = "ente-scaleway-postgres"
  policy = data.vault_policy_document.ente_scaleway_postgres.hcl
}
