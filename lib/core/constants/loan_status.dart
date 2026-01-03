enum LoanStatus {
  pending(1, 'Pending'),
  sentForApproval(2, 'Sent for Approval'),
  additionalDocsRequested(3, 'Add. Docs Requested'),
  approved(4, 'Approved'),
  sentInAudit(5, 'Sent in Audit'),
  funded(6, 'Funded');

  final int order;
  final String label;

  const LoanStatus(this.order, this.label);

  bool get isFunded => this == LoanStatus.funded;

  static LoanStatus fromIndex(int index) {
    return LoanStatus.values.firstWhere(
      (e) => e.index == index,
      orElse: () => LoanStatus.pending,
    );
  }
}
