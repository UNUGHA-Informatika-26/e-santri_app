import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

// ============================================================
// EVENT
// ============================================================

abstract class WhatsappPreviewEvent extends Equatable {
  const WhatsappPreviewEvent();

  @override
  List<Object?> get props => [];
}

class WhatsappPesanDikirim extends WhatsappPreviewEvent {
  final String pesan;

  const WhatsappPesanDikirim(this.pesan);

  @override
  List<Object?> get props => [pesan];
}

// ============================================================
// STATE
// ============================================================

class WhatsappPreviewState extends Equatable {
  final bool sedangMengirim;
  final String? pesanGagal;

  const WhatsappPreviewState({
    this.sedangMengirim = false,
    this.pesanGagal,
  });

  WhatsappPreviewState salin({
    bool? sedangMengirim,
    Object? pesanGagal = const Object(),
  }) {
    return WhatsappPreviewState(
      sedangMengirim: sedangMengirim ?? this.sedangMengirim,
      pesanGagal: identical(pesanGagal, const Object())
          ? this.pesanGagal
          : pesanGagal as String?,
    );
  }

  @override
  List<Object?> get props => [sedangMengirim, pesanGagal];
}

// ============================================================
// BLOC
// ============================================================

class WhatsappPreviewBloc
    extends Bloc<WhatsappPreviewEvent, WhatsappPreviewState> {
  WhatsappPreviewBloc() : super(const WhatsappPreviewState()) {
    on<WhatsappPesanDikirim>(_onPesanDikirim);
  }

  Future<void> _onPesanDikirim(
    WhatsappPesanDikirim event,
    Emitter<WhatsappPreviewState> emit,
  ) async {
    emit(state.salin(sedangMengirim: true, pesanGagal: null));

    final uri = Uri.parse(
      'https://wa.me/?text=${Uri.encodeComponent(event.pesan)}',
    );

    bool berhasil = false;
    try {
      berhasil = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      berhasil = false;
    }

    if (!berhasil) {
      emit(
        state.salin(
          sedangMengirim: false,
          pesanGagal: 'WhatsApp tidak bisa dibuka di perangkat ini.',
        ),
      );
    } else {
      emit(state.salin(sedangMengirim: false, pesanGagal: null));
    }
  }
}