# my_diary

Projeto pessoal em Flutter Web com foco em uma experiência simples para busca de diários.

## System design

A aplicação segue uma estrutura inspirada em Clean Architecture:

- **UI (`lib/ui`)**: páginas, widgets e view models.
- **Core (`lib/core`)**: regras de negócio, contratos e casos de uso.
- **Data (`lib/data`)**: implementações concretas de repositórios.

### Fluxo de busca de diário

1. Usuário digita o nome do diário na `LoginPage`.
2. `LoginViewModel` aciona `FindDiaryUseCase`.
3. `FindDiaryUseCase` valida a entrada com `DiaryQuery`.
4. Caso válido, consulta o contrato `DiaryRepository`.
5. `SupabaseDiaryRepository` persiste e consulta dados no Supabase quando configurado.
6. A UI exibe o resultado com `SnackBar`.

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

### Estrutura esperada da tabela `diaries`

- `id` (uuid ou text, chave primária)
- `name` (text)
- `content` (text)
- `password` (text, nullable)
- `is_public` (bool)
