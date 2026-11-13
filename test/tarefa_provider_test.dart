import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_tasks/models/categoria.dart';
import 'package:smart_tasks/models/tarefa.dart';
import 'package:smart_tasks/providers/tarefa_provider.dart';

import 'tarefa_test.dart' show hoje;

Tarefa tarefa(
  String id, {
  String titulo = 'Tarefa',
  String descricao = '',
  String categoriaId = 'pessoal',
  Prioridade prioridade = Prioridade.media,
  bool concluida = false,
  DateTime? prazo,
}) =>
    Tarefa(
      id: id,
      titulo: titulo,
      descricao: descricao,
      categoriaId: categoriaId,
      prioridade: prioridade,
      concluida: concluida,
      prazo: prazo,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TarefaProvider provider;

  List<String> ordem() => provider.tarefas.map((t) => t.id).toList();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    provider = TarefaProvider();
    await provider.carregar();
  });

  group('ordenação inteligente', () {
    test('pendentes vêm antes de concluídas', () async {
      await provider.adicionar(tarefa('concluida', concluida: true));
      await provider.adicionar(tarefa('pendente'));

      expect(ordem(), ['pendente', 'concluida']);
    });

    test('atrasada sobe ao topo mesmo com prioridade menor', () async {
      await provider
          .adicionar(tarefa('alta-no-prazo', prioridade: Prioridade.alta));
      await provider.adicionar(tarefa(
        'baixa-atrasada',
        prioridade: Prioridade.baixa,
        prazo: hoje().subtract(const Duration(days: 2)),
      ));

      expect(ordem(), ['baixa-atrasada', 'alta-no-prazo']);
    });

    test('entre tarefas equivalentes, a prioridade decide', () async {
      await provider.adicionar(tarefa('baixa', prioridade: Prioridade.baixa));
      await provider.adicionar(tarefa('alta', prioridade: Prioridade.alta));
      await provider.adicionar(tarefa('media', prioridade: Prioridade.media));

      expect(ordem(), ['alta', 'media', 'baixa']);
    });

    test(
        'na mesma prioridade, o prazo mais próximo vem primeiro e quem não tem prazo fica por último',
        () async {
      await provider.adicionar(tarefa('sem-prazo'));
      await provider.adicionar(
          tarefa('daqui-cinco-dias', prazo: hoje().add(const Duration(days: 5))));
      await provider
          .adicionar(tarefa('amanha', prazo: hoje().add(const Duration(days: 1))));

      expect(ordem(), ['amanha', 'daqui-cinco-dias', 'sem-prazo']);
    });

    test('concluir uma tarefa a manda para o fim da lista', () async {
      final primeira = tarefa('a', prioridade: Prioridade.alta);
      await provider.adicionar(primeira);
      await provider.adicionar(tarefa('b', prioridade: Prioridade.baixa));
      expect(ordem(), ['a', 'b']);

      await provider.alternarConcluida(primeira);

      expect(ordem(), ['b', 'a']);
    });
  });

  group('busca e filtros', () {
    setUp(() async {
      await provider.adicionar(tarefa(
        'relatorio',
        titulo: 'Entregar relatório',
        categoriaId: 'trabalho',
        prioridade: Prioridade.alta,
      ));
      await provider.adicionar(tarefa(
        'prova',
        titulo: 'Estudar para a prova',
        descricao: 'revisar o caderno inteiro',
        categoriaId: 'estudo',
        prioridade: Prioridade.baixa,
      ));
      await provider.adicionar(tarefa(
        'mercado',
        titulo: 'Ir ao mercado',
        categoriaId: 'pessoal',
        concluida: true,
      ));
    });

    test('busca ignora maiúsculas e minúsculas', () {
      provider.setBusca('ENTREGAR');
      expect(ordem(), ['relatorio']);
    });

    test('busca também encontra pelo texto da descrição', () {
      provider.setBusca('caderno');
      expect(ordem(), ['prova']);
    });

    test('busca sem resultado devolve lista vazia', () {
      provider.setBusca('xyz');
      expect(provider.tarefas, isEmpty);
    });

    test('filtro de categoria isola uma categoria', () {
      provider.setFiltroCategoria('estudo');
      expect(ordem(), ['prova']);
    });

    test('filtro de prioridade isola uma prioridade', () {
      provider.setFiltroPrioridade(Prioridade.alta);
      expect(ordem(), ['relatorio']);
    });

    test('filtro de situação separa pendentes de concluídas', () {
      provider.setFiltroConcluida(true);
      expect(ordem(), ['mercado']);

      provider.setFiltroConcluida(false);
      expect(ordem(), ['relatorio', 'prova']);
    });

    test('filtros e busca se acumulam em vez de se substituírem', () {
      provider.setFiltroConcluida(false);
      provider.setBusca('prova');
      expect(ordem(), ['prova']);

      provider.setFiltroCategoria('trabalho');
      expect(provider.tarefas, isEmpty);
    });

    test('passar null limpa o filtro', () {
      provider.setFiltroCategoria('estudo');
      expect(provider.tarefas, hasLength(1));

      provider.setFiltroCategoria(null);
      expect(provider.tarefas, hasLength(3));
    });

    test('o contador de pendentes ignora busca e filtros', () {
      provider.setFiltroCategoria('estudo');
      provider.setBusca('prova');

      expect(provider.tarefas, hasLength(1));
      expect(provider.pendentes, 2);
    });
  });

  group('categorias definidas pelo usuário', () {
    test('o app começa com as quatro categorias padrão', () {
      expect(
        provider.categorias.map((c) => c.nome),
        ['Trabalho', 'Estudo', 'Pessoal', 'Outros'],
      );
    });

    test('criar categoria devolve a nova e a acrescenta à lista', () async {
      final criada = await provider.adicionarCategoria('Academia');

      expect(criada, isNotNull);
      expect(provider.categorias.map((c) => c.nome), contains('Academia'));
    });

    test('nome repetido é recusado, mesmo com outra caixa', () async {
      expect(await provider.adicionarCategoria('TRABALHO'), isNull);
      expect(provider.categorias, hasLength(4));
    });

    test('nome vazio ou só espaços é recusado', () async {
      expect(await provider.adicionarCategoria('   '), isNull);
      expect(provider.categorias, hasLength(4));
    });

    test('renomear muda o rótulo sem mexer nas tarefas', () async {
      await provider.adicionar(tarefa('a', categoriaId: 'trabalho'));

      expect(
        await provider.atualizarCategoria('trabalho', nome: 'Serviço'),
        isTrue,
      );

      expect(provider.nomeCategoria('trabalho'), 'Serviço');
      expect(provider.tarefas.single.categoriaId, 'trabalho');
    });

    test('renomear para um nome que já existe é recusado', () async {
      expect(
        await provider.atualizarCategoria('trabalho', nome: 'Estudo'),
        isFalse,
      );
      expect(provider.nomeCategoria('trabalho'), 'Trabalho');
    });

    test('trocar a cor mantém o nome e persiste', () async {
      final nova = Categoria.paleta.last;

      expect(
        await provider.atualizarCategoria('trabalho',
            nome: 'Trabalho', cor: nova),
        isTrue,
      );

      expect(provider.corCategoria('trabalho'), nova);
      expect(provider.nomeCategoria('trabalho'), 'Trabalho');
    });

    test('cada categoria padrão nasce com uma cor diferente', () {
      final cores = provider.categorias.map((c) => c.cor).toSet();
      expect(cores, hasLength(provider.categorias.length));
    });

    test('categoria nova recebe uma cor ainda não usada', () async {
      final usadasAntes = provider.categorias.map((c) => c.cor).toSet();

      final criada = await provider.adicionarCategoria('Academia');

      expect(usadasAntes.contains(criada!.cor), isFalse);
    });

    test('categorias gravadas sem cor ganham cores da paleta ao carregar',
        () async {
      SharedPreferences.setMockInitialValues({
        'categorias': '[{"id":"trabalho","nome":"Trabalho"},'
            '{"id":"estudo","nome":"Estudo"}]'
      });

      final novo = TarefaProvider();
      await novo.carregar();

      final cores = novo.categorias.map((c) => c.cor).toList();
      expect(cores, everyElement(isIn(Categoria.paleta)));
      expect(cores.toSet(), hasLength(2), reason: 'cores devem ser distintas');
    });

    test('a migração de cor é gravada, não recalculada a cada abertura',
        () async {
      SharedPreferences.setMockInitialValues({
        'categorias': '[{"id":"trabalho","nome":"Trabalho"}]'
      });

      final primeiro = TarefaProvider();
      await primeiro.carregar();
      final corGravada = primeiro.corCategoria('trabalho');

      final segundo = TarefaProvider();
      await segundo.carregar();

      expect(segundo.corCategoria('trabalho'), corGravada);
    });

    test('categoria com tarefas não pode ser excluída', () async {
      await provider.adicionar(tarefa('a', categoriaId: 'estudo'));

      expect(
        await provider.excluirCategoria('estudo'),
        ResultadoExclusaoCategoria.emUso,
      );
      expect(provider.categorias, hasLength(4));
    });

    test('categoria sem tarefas é excluída', () async {
      expect(
        await provider.excluirCategoria('estudo'),
        ResultadoExclusaoCategoria.excluida,
      );
      expect(provider.categorias.map((c) => c.id), isNot(contains('estudo')));
    });

    test('a última categoria restante não pode ser excluída', () async {
      await provider.excluirCategoria('trabalho');
      await provider.excluirCategoria('estudo');
      await provider.excluirCategoria('pessoal');
      expect(provider.categorias, hasLength(1));

      expect(
        await provider.excluirCategoria('outros'),
        ResultadoExclusaoCategoria.ultimaRestante,
      );
      expect(provider.categorias, hasLength(1));
    });

    test('excluir a categoria que está filtrando limpa o filtro', () async {
      provider.setFiltroCategoria('estudo');

      await provider.excluirCategoria('estudo');

      expect(provider.filtroCategoriaId, isNull);
    });

    test('tarefa apontando para categoria inexistente mostra um rótulo neutro',
        () {
      expect(provider.nomeCategoria('id-que-nao-existe'),
          Categoria.nomeDesconhecida);
    });

    test('categorias criadas sobrevivem a uma nova instância do provider',
        () async {
      await provider.adicionarCategoria('Academia');

      final outro = TarefaProvider();
      await outro.carregar();

      expect(outro.categorias.map((c) => c.nome), contains('Academia'));
    });
  });

  group('edição e exclusão', () {
    test('atualizar troca os dados mantendo o id', () async {
      await provider.adicionar(tarefa('a', titulo: 'Antes'));

      await provider.atualizar(tarefa('a', titulo: 'Depois'));

      expect(provider.tarefas.single.id, 'a');
      expect(provider.tarefas.single.titulo, 'Depois');
    });

    test('excluir remove apenas a tarefa indicada', () async {
      await provider.adicionar(tarefa('a'));
      await provider.adicionar(tarefa('b'));

      await provider.excluir('a');

      expect(ordem(), ['b']);
    });

    test('readicionar a tarefa excluída desfaz a exclusão', () async {
      final alvo = tarefa('a', titulo: 'Excluída por engano');
      await provider.adicionar(alvo);
      await provider.excluir('a');
      expect(provider.tarefas, isEmpty);

      await provider.adicionar(alvo);

      expect(provider.tarefas.single.titulo, 'Excluída por engano');
    });
  });

  group('persistência', () {
    test('as tarefas sobrevivem a uma nova instância do provider', () async {
      await provider.adicionar(tarefa('a', titulo: 'Persistida'));

      final outro = TarefaProvider();
      await outro.carregar();

      expect(outro.tarefas.single.titulo, 'Persistida');
    });

    test('carregando é verdadeiro até a leitura do disco terminar', () async {
      final novo = TarefaProvider();
      expect(novo.carregando, isTrue);

      await novo.carregar();

      expect(novo.carregando, isFalse);
    });

    test('JSON corrompido não impede a abertura do app', () async {
      SharedPreferences.setMockInitialValues({'tarefas': 'isso não é json'});

      final novo = TarefaProvider();
      await novo.carregar();

      expect(novo.tarefas, isEmpty);
      expect(novo.carregando, isFalse);
      expect(novo.categorias, hasLength(4));
    });

    test('tarefa gravada com uma prioridade desconhecida não derruba o carregamento',
        () async {
      SharedPreferences.setMockInitialValues({
        'tarefas': '[{"id":"1","titulo":"X","descricao":"",'
            '"categoria":"trabalho","prioridade":"prioridade_que_nao_existe",'
            '"concluida":false,"criadaEm":"2026-01-01T00:00:00.000","prazo":null}]'
      });

      final novo = TarefaProvider();
      await novo.carregar();

      expect(novo.tarefas, isEmpty);
    });

    test('categorias corrompidas voltam para as padrão', () async {
      SharedPreferences.setMockInitialValues({'categorias': '{nao é lista}'});

      final novo = TarefaProvider();
      await novo.carregar();

      expect(novo.categorias, hasLength(4));
    });
  });
}
