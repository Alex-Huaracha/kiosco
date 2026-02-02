import 'dart:convert';
import 'package:hgtrack/appseguimiento/model/hgdetalleordentrabajodto_model.dart';
import 'package:hgtrack/appseguimiento/model/hgordentrabajodto_model.dart';

List<HgResponseOrdenTrabajoDto> hgResponseOrdenTrabajoDtoListFromJson(
  String str,
) =>
    List<HgResponseOrdenTrabajoDto>.from(
      json.decode(str).map((x) => HgResponseOrdenTrabajoDto.fromJson(x)),
    );

String hgResponseOrdenTrabajoDtoListToJson(
  List<HgResponseOrdenTrabajoDto> data,
) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class HgResponseOrdenTrabajoDto {
  HgOrdenTrabajoDto? ot;
  List<HgDetalleOrdenTrabajoDto>? listadot;

  HgResponseOrdenTrabajoDto({this.ot, this.listadot});

  factory HgResponseOrdenTrabajoDto.fromJson(Map<String, dynamic> json) =>
      HgResponseOrdenTrabajoDto(
        ot: json["ot"] != null ? HgOrdenTrabajoDto.fromJson(json["ot"]) : null,
        listadot: json["listadot"] != null
            ? List<HgDetalleOrdenTrabajoDto>.from(
                json["listadot"].map(
                  (x) => HgDetalleOrdenTrabajoDto.fromJson(x),
                ),
              )
            : null,
      );

  Map<String, dynamic> toJson() => {
        "ot": ot?.toJson(),
        "listadot": listadot != null
            ? List<dynamic>.from(listadot!.map((x) => x.toJson()))
            : null,
      };
}
