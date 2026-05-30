enum RequestType { cleaning, maintenance, lostItem }

enum RequestStatus { pending, accepted, completed }

extension RequestTypeExtension on RequestType {
  String get label {
    switch (this) {
      case RequestType.cleaning:
        return 'Cleaning';
      case RequestType.maintenance:
        return 'Maintenance';
      case RequestType.lostItem:
        return 'Lost Item';
    }
  }

  String get icon {
    switch (this) {
      case RequestType.cleaning:
        return '🧹';
      case RequestType.maintenance:
        return '🔧';
      case RequestType.lostItem:
        return '🔍';
    }
  }
}

extension RequestStatusExtension on RequestStatus {
  String get label {
    switch (this) {
      case RequestStatus.pending:
        return 'Pending';
      case RequestStatus.accepted:
        return 'Accepted';
      case RequestStatus.completed:
        return 'Completed';
    }
  }
}

class HostelRequest {
  final String id;
  final String studentName;
  final String roomNumber;
  final RequestType type;
  final String description;
  final DateTime createdAt;
  RequestStatus status;

  HostelRequest({
    required this.id,
    required this.studentName,
    required this.roomNumber,
    required this.type,
    required this.description,
    required this.createdAt,
    this.status = RequestStatus.pending,
  });
}

class MockRequestData {
  static List<HostelRequest> requests = [
    HostelRequest(
      id: 'REQ001',
      studentName: 'Arjun Sharma',
      roomNumber: 'B-204',
      type: RequestType.cleaning,
      description: 'Room needs deep cleaning. Bathroom floor is very dirty.',
      createdAt: DateTime.now().subtract(Duration(hours: 2)),
    ),
    HostelRequest(
      id: 'REQ002',
      studentName: 'Priya Singh',
      roomNumber: 'A-101',
      type: RequestType.cleaning,
      description: 'Please clean the corridor outside my room.',
      createdAt: DateTime.now().subtract(Duration(hours: 5)),
      status: RequestStatus.accepted,
    ),
    HostelRequest(
      id: 'REQ003',
      studentName: 'Rahul Nair',
      roomNumber: 'C-312',
      type: RequestType.maintenance,
      description: 'Ceiling fan is making noise. Needs repair.',
      createdAt: DateTime.now().subtract(Duration(hours: 1)),
    ),
    HostelRequest(
      id: 'REQ004',
      studentName: 'Sneha Reddy',
      roomNumber: 'B-105',
      type: RequestType.maintenance,
      description: 'Water tap in bathroom is leaking continuously.',
      createdAt: DateTime.now().subtract(Duration(days: 1)),
      status: RequestStatus.completed,
    ),
    HostelRequest(
      id: 'REQ005',
      studentName: 'Vikram Mehta',
      roomNumber: 'D-208',
      type: RequestType.lostItem,
      description: 'Lost my laptop charger (Dell 65W). Last seen in common room.',
      createdAt: DateTime.now().subtract(Duration(hours: 3)),
    ),
    HostelRequest(
      id: 'REQ006',
      studentName: 'Ananya Iyer',
      roomNumber: 'A-215',
      type: RequestType.cleaning,
      description: 'Dustbin hasn\'t been emptied for 3 days. Urgent.',
      createdAt: DateTime.now().subtract(Duration(minutes: 45)),
    ),
    HostelRequest(
      id: 'REQ007',
      studentName: 'Karan Patel',
      roomNumber: 'C-108',
      type: RequestType.lostItem,
      description: 'Lost blue water bottle near the gym area.',
      createdAt: DateTime.now().subtract(Duration(hours: 8)),
      status: RequestStatus.completed,
    ),
  ];
}
