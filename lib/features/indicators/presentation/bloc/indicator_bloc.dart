import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/result.dart';
import '../../../applications/domain/entities/application.dart';
import '../../domain/entities/indicator.dart';
import '../../domain/usecases/create_indicator.dart';
import '../../domain/usecases/get_indicator.dart';
import '../../domain/usecases/get_indicator_applications.dart';
import '../../domain/usecases/get_indicators.dart';
import '../../domain/usecases/set_indicator_active.dart';
import '../../domain/usecases/update_indicator.dart';
import 'indicator_event.dart';
import 'indicator_state.dart';

class IndicatorBloc extends Bloc<IndicatorEvent, IndicatorState> {
  IndicatorBloc({
    required GetIndicators getIndicators,
    required GetIndicator getIndicator,
    required CreateIndicator createIndicator,
    required UpdateIndicator updateIndicator,
    required SetIndicatorActive setIndicatorActive,
    required GetIndicatorApplications getIndicatorApplications,
  })  : _getIndicators = getIndicators,
        _getIndicator = getIndicator,
        _createIndicator = createIndicator,
        _updateIndicator = updateIndicator,
        _setIndicatorActive = setIndicatorActive,
        _getIndicatorApplications = getIndicatorApplications,
        super(const IndicatorState()) {
    on<LoadIndicatorsEvent>(_onLoadIndicators);
    on<LoadIndicatorEvent>(_onLoadIndicator);
    on<CreateIndicatorEvent>(_onCreateIndicator);
    on<UpdateIndicatorEvent>(_onUpdateIndicator);
    on<SetIndicatorActiveEvent>(_onSetIndicatorActive);
    on<LoadIndicatorApplicationsEvent>(_onLoadIndicatorApplications);
  }

  final GetIndicators _getIndicators;
  final GetIndicator _getIndicator;
  final CreateIndicator _createIndicator;
  final UpdateIndicator _updateIndicator;
  final SetIndicatorActive _setIndicatorActive;
  final GetIndicatorApplications _getIndicatorApplications;

  Future<void> _onLoadIndicators(
    LoadIndicatorsEvent event,
    Emitter<IndicatorState> emit,
  ) async {
    emit(
      state.copyWith(
        status: IndicatorStatus.loading,
        errorMessage: '',
        clearSelectedIndicator: true,
      ),
    );

    final result = await _getIndicators(includeInactive: event.includeInactive);

    if (result is Success<List<Indicator>>) {
      emit(
        state.copyWith(
          status: IndicatorStatus.success,
          indicators: result.data,
          selectedIndicatorApplications: const [],
          isLoadingIndicatorApplications: false,
          errorMessage: '',
          clearSelectedIndicator: true,
        ),
      );
      return;
    }

    if (result is FailureResult<List<Indicator>>) {
      emit(
        state.copyWith(
          status: IndicatorStatus.error,
          errorMessage: result.failure.message,
        ),
      );
    }
  }

  Future<void> _onLoadIndicator(
    LoadIndicatorEvent event,
    Emitter<IndicatorState> emit,
  ) async {
    emit(
      state.copyWith(
        status: IndicatorStatus.loading,
        errorMessage: '',
      ),
    );

    final result = await _getIndicator(event.id);

    if (result is Success<Indicator>) {
      final selected = result.data;
      emit(
        state.copyWith(
          status: IndicatorStatus.success,
          selectedIndicator: selected,
          indicators: _upsertById(state.indicators, selected),
          selectedIndicatorApplications: const [],
          isLoadingIndicatorApplications: false,
          errorMessage: '',
        ),
      );
      final id = selected.id?.trim() ?? '';
      if (id.isNotEmpty) {
        add(LoadIndicatorApplicationsEvent(id));
      }
      return;
    }

    if (result is FailureResult<Indicator>) {
      emit(
        state.copyWith(
          status: IndicatorStatus.error,
          errorMessage: result.failure.message,
        ),
      );
    }
  }

  Future<void> _onSetIndicatorActive(
    SetIndicatorActiveEvent event,
    Emitter<IndicatorState> emit,
  ) async {
    emit(state.copyWith(status: IndicatorStatus.loading, errorMessage: ''));

    final result = await _setIndicatorActive(id: event.id, active: event.active);

    if (result is Success<Indicator>) {
      final updated = result.data;
      emit(
        state.copyWith(
          status: IndicatorStatus.success,
          selectedIndicator:
              state.selectedIndicator?.id == updated.id ? updated : state.selectedIndicator,
          indicators: _upsertById(state.indicators, updated),
          errorMessage: '',
        ),
      );

      final selectedId = state.selectedIndicator?.id?.trim() ?? '';
      if (selectedId.isNotEmpty && selectedId == updated.id?.trim()) {
        add(LoadIndicatorApplicationsEvent(selectedId));
      }
      return;
    }

    if (result is FailureResult<Indicator>) {
      emit(
        state.copyWith(
          status: IndicatorStatus.error,
          errorMessage: result.failure.message,
        ),
      );
    }
  }

  Future<void> _onLoadIndicatorApplications(
    LoadIndicatorApplicationsEvent event,
    Emitter<IndicatorState> emit,
  ) async {
    emit(state.copyWith(isLoadingIndicatorApplications: true, errorMessage: ''));

    final result = await _getIndicatorApplications(event.indicatorId);

    if (result is Success<List<Application>>) {
      emit(
        state.copyWith(
          isLoadingIndicatorApplications: false,
          selectedIndicatorApplications: List.unmodifiable(result.data),
          errorMessage: '',
        ),
      );
      return;
    }

    if (result is FailureResult<List<Application>>) {
      emit(
        state.copyWith(
          isLoadingIndicatorApplications: false,
          status: IndicatorStatus.error,
          errorMessage: result.failure.message,
        ),
      );
    }
  }

  Future<void> _onCreateIndicator(
    CreateIndicatorEvent event,
    Emitter<IndicatorState> emit,
  ) async {
    emit(
      state.copyWith(
        status: IndicatorStatus.loading,
        errorMessage: '',
      ),
    );

    final result = await _createIndicator(event.indicator);

    if (result is Success<Indicator>) {
      final created = result.data;
      emit(
        state.copyWith(
          status: IndicatorStatus.success,
          selectedIndicator: created,
          indicators: _upsertById(state.indicators, created),
          errorMessage: '',
        ),
      );
      return;
    }

    if (result is FailureResult<Indicator>) {
      emit(
        state.copyWith(
          status: IndicatorStatus.error,
          errorMessage: result.failure.message,
        ),
      );
    }
  }

  Future<void> _onUpdateIndicator(
    UpdateIndicatorEvent event,
    Emitter<IndicatorState> emit,
  ) async {
    emit(
      state.copyWith(
        status: IndicatorStatus.loading,
        errorMessage: '',
      ),
    );

    final result = await _updateIndicator(event.indicator);

    if (result is Success<Indicator>) {
      final updated = result.data;
      emit(
        state.copyWith(
          status: IndicatorStatus.success,
          selectedIndicator: updated,
          indicators: _upsertById(state.indicators, updated),
          errorMessage: '',
        ),
      );
      return;
    }

    if (result is FailureResult<Indicator>) {
      emit(
        state.copyWith(
          status: IndicatorStatus.error,
          errorMessage: result.failure.message,
        ),
      );
    }
  }

  List<Indicator> _upsertById(
    List<Indicator> current,
    Indicator indicator,
  ) {
    final next = List<Indicator>.from(current);
    final index = next.indexWhere(
      (item) =>
          item.id != null &&
          indicator.id != null &&
          item.id == indicator.id,
    );

    if (index >= 0) {
      next[index] = indicator;
      return List<Indicator>.unmodifiable(next);
    }

    next.add(indicator);
    return List<Indicator>.unmodifiable(next);
  }
}
