# Smart Tasks

Gerenciador de tarefas inteligente desenvolvido em **Flutter**, para a disciplina
*Explorando Tecnologias Móveis* (Unochapecó — prof. Cezar Junior de Souza).

O aplicativo vai além de uma lista de afazeres: ele **reorganiza as tarefas sozinho**,
destacando o que está atrasado e o que é mais urgente, sem que o usuário precise ordenar
nada manualmente.

## Funcionalidades

### Obrigatórias

- **Criar, editar e excluir tarefas** — formulário com validação de título; edição ao tocar
  na tarefa; exclusão por deslize lateral ou pelo botão dentro da edição
- **Categorias** — Trabalho, Estudo, Pessoal e Outros
- **Prioridades** — Alta, Média e Baixa, com indicador colorido em cada item
- **Marcar como concluída** — caixa de seleção que risca o título e reposiciona a tarefa
- **Buscar e filtrar** — busca por título *e* descrição, combinada com filtros de categoria,
  prioridade e situação
- **Persistência local** — os dados sobrevivem ao fechamento do app, via `shared_preferences`

### Diferenciais "inteligentes"

- **Ordenação automática** — a lista se reordena sozinha seguindo esta hierarquia:

  1. Pendentes antes de concluídas
  2. Atrasadas no topo
  3. Prioridade (Alta → Média → Baixa)
  4. Prazo mais próximo primeiro

- **Destaque de tarefas atrasadas** — ícone de alerta e texto em vermelho para prazos vencidos
- **Contador de pendentes** — exibido no título da tela, atualizado em tempo real

## Telas

### Lista de tarefas

A ordenação inteligente em ação: a tarefa atrasada aparece em vermelho no topo, seguida pelas
pendentes por prioridade e prazo; a concluída fica por último, riscada.

![Lista de tarefas](docs/screenshots/01-lista.png)

### Cadastro e edição

![Formulário de tarefa](docs/screenshots/02-formulario.png)

### Busca e filtros

Filtro de categoria "Estudo" aplicado:

![Filtros](docs/screenshots/03-filtros.png)

## Como rodar o projeto

Pré-requisitos: [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.13 ou superior.

```bash
git clone https://github.com/bdalpaz/smart-tasks-flutter.git
cd smart-tasks-flutter
flutter pub get
flutter run
```

Para escolher a plataforma:

```bash
flutter devices              # lista os dispositivos disponíveis
flutter run -d windows       # desktop
flutter run -d chrome        # navegador
flutter run -d <id-android>  # celular ou emulador
```

## Build e APK

```bash
flutter build apk --release
```

O arquivo é gerado em `build/app/outputs/flutter-apk/app-release.apk` (~49 MB).

**Download:** veja a [Release v1.0](https://github.com/bdalpaz/smart-tasks-flutter/releases/tag/v1.0).

> O APK é assinado com a chave de depuração padrão do Flutter, o que é suficiente para
> instalar e testar no dispositivo. Para publicação em loja seria necessário configurar uma
> chave de assinatura própria.

## Estrutura do projeto

```
lib/
├── main.dart                        # ponto de entrada e configuração do tema
├── models/
│   └── tarefa.dart                  # modelo, enums, serialização JSON e regra de "atrasada"
├── providers/
│   └── tarefa_provider.dart         # estado, filtros, busca e ordenação inteligente
├── data/
│   └── tarefa_repository.dart       # persistência via shared_preferences
└── screens/
    ├── lista_tarefas_screen.dart    # tela principal, filtros e itens da lista
    └── form_tarefa_screen.dart      # cadastro e edição
```

A separação segue a ideia de camadas: a **tela** só desenha e dispara ações, o **provider**
concentra as regras de negócio e notifica a interface, e o **repositório** cuida do
armazenamento. Trocar `shared_preferences` por um banco local exigiria mexer em um único
arquivo.

## Tecnologias utilizadas

| Recurso | Uso no projeto |
|---|---|
| [Flutter](https://flutter.dev) 3.x / Dart | Framework e linguagem |
| [Material 3](https://m3.material.io/) | Design system da interface |
| [provider](https://pub.dev/packages/provider) `^6.1.5` | Gerenciamento de estado (`ChangeNotifier`) |
| [shared_preferences](https://pub.dev/packages/shared_preferences) `^2.5.6` | Persistência local em JSON |

## Integrantes

<!-- TODO: substituir pelos nomes do grupo -->

- *(a preencher)*

## Licença

Projeto acadêmico, sem fins comerciais.
