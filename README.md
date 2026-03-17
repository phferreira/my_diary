# my_diary

Projeto pessoal em Flutter Web com foco em uma experiência simples para criar e escrever diários.

GitHub Pages: https://phferreira.github.io/my_diary/

## Funcionalidades

- Buscar diários por nome e desbloquear com senha quando necessário.
- Criar novos diários com opção de senha e controle de visibilidade (público/privado).
- Editor rico por data, com navegação diária/mensal e salvamento automático manual.
- Persistência em Supabase quando configurado, com fallback local em memória.

## System design

A aplicação segue uma estrutura inspirada em Clean Architecture:

- **UI (`lib/ui`)**: páginas, widgets e view models.
- **Core (`lib/core`)**: regras de negócio, contratos e casos de uso.
- **Data (`lib/data`)**: implementações concretas de repositórios.

### Fluxo de acesso ao diário

1. Usuário digita o nome do diário na `LoginPage`.
2. `LoginViewModel` aciona `FindDiaryUseCase`.
3. `FindDiaryUseCase` valida a entrada com `DiaryQuery`.
4. Caso válido, consulta `DiaryRepository`.
5. Se existir e estiver protegido, a UI pede a senha; se não existir, oferece a criação.
6. Ao abrir, navega para `DiaryEditorPage`.

### Fluxo de edição de entradas

1. `DiaryEditorPage` carrega a entrada do dia via `LoadDiaryEntryUseCase`.
2. O conteúdo é editado com `flutter_quill` e salvo via `SaveDiaryEntryUseCase`.
3. A visibilidade do diário é atualizada com `UpdateDiaryAccessUseCase`.
4. A UI mostra feedbacks com `SnackBar`.

### Dependências entre camadas

- UI depende do Core via casos de uso.
- Data depende do Core via abstrações de repositório.
- Core não depende de UI nem de Data.

## Configuração de ambiente (Supabase)

Os dados sensíveis são lidos de variáveis de ambiente em tempo de build usando `--dart-define`, evitando hardcode de chaves no código.

### Variáveis obrigatórias

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

### Executar localmente

```bash
fvm flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://SEU-PROJETO.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=SUA_CHAVE_ANON
```

Se você não usa `fvm`, substitua o comando acima por `flutter run -d chrome`.

Quando as variáveis não são informadas, o app usa `InMemoryDiaryRepository` como fallback para facilitar desenvolvimento local.

### Estrutura esperada das tabelas no Supabase

#### `tb_diaries`

- `id` (uuid ou text, chave primária)
- `name` (text)
- `content` (text)
- `password` (text, nullable)
- `is_public` (bool)

#### `tb_diary_entries`

- `diary_id` (uuid ou text, chave estrangeira)
- `entry_date` (date)
- `content` (text)

Sugestão: índice único em `(diary_id, entry_date)` para suportar `upsert`.
