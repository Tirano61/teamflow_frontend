import 'dart:async';

import 'package:flutter/material.dart';

/// Pide la pagina siguiente del listado de discussions cuando alguno de los
/// listados verticales de [child] (la columna del layout compacto o las
/// columnas del kanban) se acerca a su final.
///
/// Tambien cubre pantallas altas (Flutter Web): si ningun listado tiene
/// contenido suficiente para desplazarse y [enabled] indica que hay mas
/// paginas, pide la siguiente sin esperar un scroll. Para no entrar en un
/// bucle, ese pedido automatico se hace a lo sumo una vez por cantidad de
/// discussions cargadas.
class DiscussionInfiniteScroll extends StatefulWidget {
  const DiscussionInfiniteScroll({
    required this.enabled,
    required this.loadedCount,
    required this.onLoadMore,
    required this.child,
    this.loadOnScrollEnd = true,
    this.fillViewport = true,
    super.key,
  });

  /// Hay pagina siguiente y no hay una en curso ni un error pendiente.
  final bool enabled;

  /// Discussions cargadas; cambia cada vez que llega una pagina.
  final int loadedCount;
  final VoidCallback onLoadMore;
  final Widget child;

  /// Pedir al acercarse al final de un listado.
  final bool loadOnScrollEnd;

  /// Pedir cuando ningun listado puede desplazarse.
  final bool fillViewport;

  @override
  State<DiscussionInfiniteScroll> createState() =>
      _DiscussionInfiniteScrollState();
}

class _DiscussionInfiniteScrollState extends State<DiscussionInfiniteScroll> {
  /// Precarga: se pide la pagina siguiente cuando queda menos de este
  /// multiplo del alto visible por recorrer.
  static const double _preloadViewportFraction = 1.0;

  /// Recorrido maximo de cada listado vertical, segun su ultimo layout.
  final Map<BuildContext, double> _maxScrollExtents = {};

  bool _fillCheckScheduled = false;
  int? _autoFilledAtCount;

  @override
  void initState() {
    super.initState();
    _scheduleFillCheck();
  }

  @override
  void didUpdateWidget(covariant DiscussionInfiniteScroll oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled ||
        oldWidget.loadedCount != widget.loadedCount) {
      _scheduleFillCheck();
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: _onMetricsChanged,
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: widget.child,
      ),
    );
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification.depth != 0 || notification.metrics.axis != Axis.vertical) {
      return false;
    }

    if (widget.loadOnScrollEnd &&
        (notification is ScrollUpdateNotification ||
            notification is OverscrollNotification)) {
      final metrics = notification.metrics;
      if (metrics.extentAfter <
          metrics.viewportDimension * _preloadViewportFraction) {
        _requestLoadMore();
      }
    }
    return false;
  }

  bool _onMetricsChanged(ScrollMetricsNotification notification) {
    if (notification.depth != 0 || notification.metrics.axis != Axis.vertical) {
      return false;
    }

    _maxScrollExtents[notification.context] =
        notification.metrics.maxScrollExtent;
    _scheduleFillCheck();
    return false;
  }

  void _requestLoadMore() {
    if (widget.enabled) {
      widget.onLoadMore();
    }
  }

  void _scheduleFillCheck() {
    if (_fillCheckScheduled) {
      return;
    }
    _fillCheckScheduled = true;
    // Las ScrollMetricsNotification del layout se despachan en una microtask
    // encolada durante el frame: el chequeo va despues de ellas para conocer
    // el recorrido real de cada listado.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scheduleMicrotask(() {
        _fillCheckScheduled = false;
        if (mounted) {
          _fillViewportIfNeeded();
        }
      });
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  /// Si nada se puede desplazar, el usuario no tiene como llegar al final:
  /// se pide la pagina siguiente (una vez por cantidad cargada).
  void _fillViewportIfNeeded() {
    _maxScrollExtents.removeWhere((scrollable, _) => !scrollable.mounted);

    if (!widget.fillViewport ||
        !widget.enabled ||
        _autoFilledAtCount == widget.loadedCount) {
      return;
    }

    final anyScrollable = _maxScrollExtents.values.any((extent) => extent > 0);
    if (anyScrollable) {
      return;
    }

    _autoFilledAtCount = widget.loadedCount;
    widget.onLoadMore();
  }
}
