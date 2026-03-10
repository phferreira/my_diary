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
5. `InMemoryDiaryRepository` retorna o diário correspondente (ou `null`).
6. A UI exibe o resultado com `SnackBar`.

### Dependências entre camadas

- UI depende do Core via casos de uso.
- Data depende do Core via abstrações de repositório.
- Core não depende de UI nem de Data.
