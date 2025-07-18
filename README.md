# 🐘 Gerenciador de Múltiplas Instâncias do PostgreSQL

Este é um **script Windows Batch** que permite gerenciar múltiplas instâncias do PostgreSQL na mesma máquina, **sem a necessidade de instalar o PostgreSQL como serviço do sistema**. Cada instância pode ser iniciada e parada independentemente, com versões diferentes, portas distintas e sem conflitos.

---

## 📁 Estrutura de Pastas Recomendada

O script espera que as instâncias estejam organizadas dentro de um diretório raiz chamado `C:\PostgreSQL` (configurável no script), com a seguinte estrutura:

```
│   C:\PostgreSQL\
│   │   postgresql-9.5\
│   │   └───pgsql\
│   │       ├───bin
│   │       ├───data
│   │       └───logfile
│   │
│   │   postgresql-14.5\
│   │   └───pgsql\
│   │       ├───bin
│   │       ├───data
│   │       └───logfile
│   │
│   └───postgresql-17.5.3\
│       └───pgsql\
│           ├───bin
│           ├───data
│           └───logfile
```


Dentro de cada pasta `pgsql`, devem estar os binários do PostgreSQL e a pasta `data` (para o cluster do banco de dados).

---

## 🛠️ Funcionalidades

- ✅ **Listagem automática** das versões disponíveis em `C:\PostgreSQL`.
- 🔍 **Detecção de instâncias em execução** com exibição da versão e porta.
- ⚙️ **Iniciar PostgreSQL** com porta personalizada.
- 🚫 **Parar PostgreSQL** se já estiver rodando.
- 🧱 **Criar novo cluster** caso não exista.
- 🧪 **Validação de porta** (número entre 1 e 65535).
- 📋 **Log de execução** salvo em `logfile` dentro da pasta da instância.

---

## 📦 Requisitos

- Windows 10 ou superior.
- Pasta `C:\PostgreSQL` criada com as instâncias descompactadas conforme a estrutura.
- Binários do PostgreSQL (versão compilada para Windows) dentro de cada pasta `pgsql`.

---

## 📥 Como Usar

1. **Baixe ou compile** os binários do PostgreSQL para Windows.
2. **Descompacte** cada versão em uma pasta dentro de `C:\PostgreSQL`, seguindo o padrão:
C:\PostgreSQL\postgresql-14.5\pgsql

3. **Edite o script (opcional)** para alterar o caminho `POSTGRES_ROOT`, se necessário.
4. **Execute o script `.bat`** com permissões de administrador.
5. **Siga as instruções no prompt** para selecionar a versão e porta desejada.

---

## 📝 Exemplo de Uso

```bat
Escolha o número da versão: 2
Digite a porta para iniciar o PostgreSQL (ex: 5433): 5434