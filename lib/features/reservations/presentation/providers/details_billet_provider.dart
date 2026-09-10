import 'package:flutter_riverpod/flutter_riverpod.dart';

class DetailsBilletState {
  final String? selectedSeat;
  final String ticketId;
  final bool isLoading;

  const DetailsBilletState({
    this.selectedSeat,
    this.ticketId = '',
    this.isLoading = false,
  });

  DetailsBilletState copyWith({
    String? selectedSeat,
    String? ticketId,
    bool? isLoading,
    bool clearSelectedSeat = false,
  }) {
    return DetailsBilletState(
      selectedSeat: clearSelectedSeat
          ? null
          : selectedSeat ?? this.selectedSeat,
      ticketId: ticketId ?? this.ticketId,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class DetailsBilletNotifier extends Notifier<DetailsBilletState> {
  @override
  DetailsBilletState build() => const DetailsBilletState();

  void selectSeat(String seatLabel) {
    if (state.selectedSeat == seatLabel) {
      state = state.copyWith(clearSelectedSeat: true);
    } else {
      state = state.copyWith(selectedSeat: seatLabel);
    }
  }

  void setTicketId(String id) {
    state = state.copyWith(ticketId: id);
  }

  void resetSelection() {
    state = state.copyWith(clearSelectedSeat: true);
  }
}

final detailsBilletProvider =
    NotifierProvider<DetailsBilletNotifier, DetailsBilletState>(
      DetailsBilletNotifier.new,
    );
