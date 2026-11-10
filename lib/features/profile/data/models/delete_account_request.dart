class DeleteAccountRequest {
  final String reason;

  const DeleteAccountRequest({required this.reason});

  Map<String, dynamic> toJson() => {'reason': reason};
}
