# Dificuldades enfrentadas no desenvolvimento

Registro dos problemas reais encontrados durante a configuração do ambiente e o
desenvolvimento do Smart Tasks, com sintoma, causa e solução. Serve de material para o
bloco B do seminário ("Configuração do ambiente de desenvolvimento").

---

## 1. PATH do Flutter no Windows

**Sintoma:** `flutter` não é reconhecido como comando no terminal.

**Causa:** o SDK do Flutter é distribuído como um ZIP, sem instalador. O diretório
`flutter\bin` precisa ser adicionado manualmente à variável de ambiente `PATH`.

**Solução:** acrescentar `flutter\bin` ao `PATH` do usuário e **reabrir o terminal** — sessões
já abertas mantêm a cópia antiga das variáveis de ambiente.

---

## 2. Modo de Desenvolvedor do Windows

**Sintoma:** o build para Windows falha pedindo que o Modo de Desenvolvedor seja ativado.

**Causa:** o Flutter usa *symlinks* para resolver plugins, e no Windows a criação de links
simbólicos exige privilégio elevado — liberado pelo Modo de Desenvolvedor.

**Solução:** `start ms-settings:developers` e ativar a opção.

---

## 3. Projeto dentro de pasta do OneDrive

Foi a dificuldade mais custosa, e com dois efeitos distintos.

**Sintoma A:** builds inconsistentes e arquivos reaparecendo. A sincronização do OneDrive
mexe nos arquivos enquanto o build escreve na pasta `build/`.

**Sintoma B:** `flutter analyze` falha com `analysis server exited with code 255`, e o
`stderr` mostra:

```
FormatException: Unexpected end of input (at character 501)
.../smart-tasks-flutter/"}],"capabilities":{"window":{"workDoneProgress":true}
```

**Causa B:** o caminho continha caracteres não-ASCII (`Área de Trabalho`, `⚝`). O
*analysis server* conversa com a CLI por LSP sobre JSON com cabeçalho `Content-Length`; o
comprimento era calculado em caracteres e não em bytes UTF-8, truncando a mensagem no meio
do `rootUri`. Curiosidade: `dart analyze` funcionava normalmente no mesmo diretório, porque
não usa o mesmo canal.

**Solução:** mover o projeto para um caminho curto e puramente ASCII — `C:\dev\smart-tasks-flutter`.
No novo caminho o mesmo comando roda sem erro.

**Lição:** caminho de projeto deve ser curto, sem espaços, sem acentos e fora de pastas
sincronizadas na nuvem.

---

## 4. O `.gitignore` ignorando o Gradle wrapper

**Sintoma:** ao tentar versionar o wrapper:

```
The following paths are ignored by one of your .gitignore files:
android/gradle/wrapper/gradle-wrapper.jar
hint: Use -f if you really want to add them.
```

**Causa:** o `.gitignore` padrão do Flutter ignora `*.jar`. Só que
`gradle-wrapper.jar` **deve** ser versionado: é ele que permite a qualquer pessoa compilar o
projeto sem ter o Gradle instalado na versão correta.

**Solução:** `git add -f android/gradle/wrapper/gradle-wrapper.jar`.

---

## 5. Push rejeitado por histórico divergente

**Sintoma:**

```
! [rejected]  main -> main (fetch first)
error: failed to push some refs
```

**Causa:** existiam **duas cópias do repositório** em pastas diferentes (a do OneDrive e a de
`C:\dev`), com commits próprios. O remoto tinha trabalho que a cópia local não tinha.

**Solução:** `git pull` antes do push e, principalmente, eleger **uma única pasta de
trabalho**. Dois clones do mesmo projeto em máquinas de uma pessoa só é fonte garantida de
confusão.

---

## 6. Marcadores de conflito commitados

**Sintoma:** o projeto não compilava, mas procurar por `<<<<<<<` nos arquivos não encontrava
nada.

**Causa:** os marcadores tinham sido **commitados** num merge anterior. Em uma das cópias o
working tree já estava corrigido (mas sem commit), enquanto a outra, de árvore limpa,
mostrava os arquivos quebrados. Buscar no disco examina só a cópia atual.

**Solução:** procurar no conteúdo versionado, não no disco:

```bash
git grep -n -E '^(<<<<<<<|=======|>>>>>>>)' origin/main
```

Foram 5 blocos de conflito em 2 arquivos. Como brinde, descobriu-se que
`lista_tarefas_screen.dart` estava truncado no meio de um widget — o arquivo terminava sem
fechar o `Scaffold` e referenciava duas classes que não existiam.

---

## 7. NDK ausente ao gerar o APK

**Sintoma:**

```
Android sdkmanager did not install NDK 28.2.13676358
BUILD FAILED
```

**Causa:** o NDK exigido não estava no SDK local (só a versão 27.1.12297006), e o aviso
`The SDK Manager CLI tool (sdkmanager) is deprecated` indicava atrito na instalação
automática.

**Tentativa errada:** fixar `ndkVersion = "27.1.12297006"` no `android/app/build.gradle.kts`,
supondo que nenhuma dependência usasse código nativo. O build passou, **mas emitiu o aviso**:

```
- jni requires Android NDK 28.2.13676358
- shared_preferences_android requires Android NDK 28.2.13676358
```

Ou seja: o `shared_preferences` depende de `jni`, que precisa do NDK 28. A suposição estava
errada.

**Solução:** reverter para `ndkVersion = flutter.ndkVersion`. A própria tentativa de build
havia instalado o NDK 28.2.13676358 e o Android SDK Platform 35 que faltavam, então o
problema original já não existia.

**Lição:** antes de contornar um erro de build, ler o log inteiro — o aviso que explica o
problema costuma estar algumas linhas depois da mensagem de erro.

---

## Resumo para o slide

| Problema | Raiz | Lição |
|---|---|---|
| `flutter` não encontrado | PATH não configurado | SDK em ZIP exige configuração manual |
| Build pedindo Modo de Desenvolvedor | symlinks no Windows | Ativar antes de começar |
| Analyzer quebrando sem motivo | acentos no caminho + OneDrive | Caminho curto, ASCII e local |
| Wrapper fora do versionamento | `.gitignore` com `*.jar` | `gradle-wrapper.jar` é exceção |
| Push rejeitado | duas cópias do repositório | Uma pasta de trabalho só |
| Conflitos invisíveis | marcadores commitados | Procurar no histórico, não no disco |
| APK não compilava | NDK ausente | Ler o log inteiro antes de contornar |
