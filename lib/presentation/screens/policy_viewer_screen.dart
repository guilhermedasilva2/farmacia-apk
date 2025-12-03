import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:meu_app_inicial/core/services/policy_service.dart';
import 'package:meu_app_inicial/core/services/prefs_service.dart';

class PolicyViewerScreen extends StatefulWidget {
  const PolicyViewerScreen({super.key});

  @override
  State<PolicyViewerScreen> createState() => _PolicyViewerScreenState();
}

class _PolicyViewerScreenState extends State<PolicyViewerScreen> {
  final ScrollController _scrollController = ScrollController();
  double _readProgress = 0;
  bool _reachedEnd = false;
  bool _marking = false;
  late final PrefsService _prefsService;
  late final PolicyService _policyService;
  Future<String>? _mdFuture;
  PolicyDocument _document = PolicyDocument.privacy;
  String? _nextRouteOnComplete; // if null, pop with result
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      if (args['doc'] == 'terms') {
        _document = PolicyDocument.terms;
      } else {
        _document = PolicyDocument.privacy;
      }
      _nextRouteOnComplete = args['nextRoute'] as String?;
    }
    _mdFuture = PrefsService.create().then((prefs) {
      _prefsService = prefs;
      _policyService = PolicyService(prefsService: _prefsService, privacyVersion: 1, termsVersion: 1);
      return _policyService.loadMarkdown(_document);
    });
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleScroll());
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (!position.hasContentDimensions) return;
    final max = position.maxScrollExtent;
    final offset = position.pixels;
    final progress = (max <= 0) ? 1.0 : (offset.clamp(0, max) / max);
    final reachedEnd = progress >= 0.999 || offset >= (max - 2);
    setState(() {
      _readProgress = progress;
      _reachedEnd = reachedEnd;
    });
  }

  Future<void> _markAsReadAndContinue() async {
    setState(() => _marking = true);
    await _policyService.markRead(_document);
    if (!mounted) return;
    setState(() => _marking = false);
    if (_nextRouteOnComplete == null) {
      Navigator.of(context).pop(true);
    } else {
      Navigator.of(context).pushReplacementNamed(_nextRouteOnComplete!);
    }
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_document == PolicyDocument.privacy ? 'Políticas de Privacidade (LGPD)' : 'Termos de Uso'),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              LinearProgressIndicator(
                value: (_readProgress).clamp(0, 1),
                minHeight: 4,
              ),
              Expanded(
                child: FutureBuilder<String>(
                  future: _mdFuture,
                  builder: (context, snapshot) {
                    if (_mdFuture == null || !snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    // Após renderizar o conteúdo, verifica se cabe na tela e marca como lido automaticamente
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (_scrollController.hasClients) {
                        final pos = _scrollController.position;
                        if (pos.hasContentDimensions && pos.maxScrollExtent <= 0 && !_reachedEnd) {
                          setState(() {
                            _readProgress = 1.0;
                            _reachedEnd = true;
                          });
                        }
                      }
                    });
                    return Scrollbar(
                      controller: _scrollController,
                      child: Markdown(
                        controller: _scrollController,
                        selectable: false,
                        data: snapshot.data!,
                        physics: const AlwaysScrollableScrollPhysics(),
                        styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Semantics(
                  button: true,
                  label: 'Marcar políticas como lidas e continuar',
                  child: ElevatedButton.icon(
                    onPressed: (_reachedEnd && !_marking) ? _markAsReadAndContinue : null,
                    icon: const Icon(Icons.check),
                    label: Text(_marking ? 'Salvando...' : 'Marcar como lido e continuar'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Botão "Ir para o topo" - canto superior direito
          if (_readProgress > 0.05) // Mostra apenas se não estiver no topo
            Positioned(
              top: 16,
              right: 16,
              child: FloatingActionButton.small(
                heroTag: 'scroll_up',
                onPressed: () {
                  _scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOut,
                  );
                },
                tooltip: 'Ir para o topo',
                child: const Icon(Icons.arrow_upward),
              ),
            ),
          // Botão "Rolar para baixo" - canto inferior direito
          if (_readProgress < 0.95) // Mostra apenas se não estiver no final
            Positioned(
              bottom: 90, // Acima do botão "Marcar como lido"
              right: 16,
              child: GestureDetector(
                onLongPressStart: (_) => _startScrollingDown(),
                onLongPressEnd: (_) => _stopScrollingDown(),
                child: FloatingActionButton.small(
                  heroTag: 'scroll_down',
                  onPressed: () {
                    // Tap único: rola um pouco
                    final currentPos = _scrollController.position.pixels;
                    final maxScroll = _scrollController.position.maxScrollExtent;
                    final targetPos = (currentPos + 200).clamp(0.0, maxScroll);
                    _scrollController.animateTo(
                      targetPos,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  },
                  tooltip: 'Segurar para rolar para baixo',
                  child: const Icon(Icons.arrow_downward),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Timer? _scrollTimer;

  void _startScrollingDown() {
    _scrollTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!_scrollController.hasClients) {
        timer.cancel();
        return;
      }
      final currentPos = _scrollController.position.pixels;
      final maxScroll = _scrollController.position.maxScrollExtent;
      if (currentPos >= maxScroll) {
        timer.cancel();
        return;
      }
      _scrollController.jumpTo((currentPos + 10).clamp(0.0, maxScroll));
    });
  }

  void _stopScrollingDown() {
    _scrollTimer?.cancel();
    _scrollTimer = null;
  }
}

