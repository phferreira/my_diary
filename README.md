# My Diary

Site pessoal em Flutter Web para criar diários, escrever entradas por data e configurar acesso privado ou público somente para leitura.

GitHub Pages: https://phferreira.github.io/my_diary/

## Desenvolvimento

O Flutter Web usa a API Python mantida separadamente em `../../python/my_diary_bk`. Configure a origem HTTPS pública da API por `API_BASE_URL`:

Crie `.env.development` na raiz do projeto com a configuração em JSON:

```json
{
  "API_BASE_URL": "http://localhost:8000"
}
```

As configurações do VS Code carregam esse arquivo. Para executar pelo terminal:

```bash
fvm flutter run -d chrome --dart-define-from-file=.env.development
```

HTTP é aceito apenas para `localhost` no desenvolvimento local. Builds de produção devem usar HTTPS. Sem uma URL válida, a tela de login informa a configuração ausente e nenhuma persistência local de fallback é usada.

O deploy do GitHub Pages lê a variável de repositório `API_BASE_URL`. Configure esse valor com a origem HTTPS do backend.

## Arquitetura

- **UI (`lib/ui`)** apresenta as jornadas e o estado das operações.
- **Core (`lib/core`)** contém entidades seguras, contratos e casos de uso.
- **Data (`lib/data`)** implementa o contrato de repositório por meio de uma abstração HTTP e Dio.
- **Backend** verifica senhas, autoriza tokens escopados e persiste dados no PostgreSQL.

Tokens de acesso são mantidos somente em memória pelo repositório Flutter. Senhas não são persistidas no cliente e hashes nunca são enviados pelo backend.

## Qualidade

```bash
fvm flutter pub get
fvm flutter analyze
fvm flutter test
```
