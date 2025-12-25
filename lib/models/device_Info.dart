class DeviceInfo {
  final Device device;
  final Cpu cpu;
  final Memory memory;
  final Disk disk;
  final System system;

  DeviceInfo({
    required this.device,
    required this.cpu,
    required this.memory,
    required this.disk,
    required this.system,
  });

  factory DeviceInfo.fromJson(Map<String, dynamic> json) {
    return DeviceInfo(
      device: Device.fromJson(json['device']),
      cpu: Cpu.fromJson(json['cpu']),
      memory: Memory.fromJson(json['memory']),
      disk: Disk.fromJson(json['disk']),
      system: System.fromJson(json['system']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'device': device.toJson(),
      'cpu': cpu.toJson(),
      'memory': memory.toJson(),
      'disk': disk.toJson(),
      'system': system.toJson(),
    };
  }
}

class Device {
  final String name;
  final String id;
  final String productId;

  Device({
    required this.name,
    required this.id,
    required this.productId,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      name: json['name'],
      id: json['id'],
      productId: json['product_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'id': id,
      'product_id': productId,
    };
  }
}

class Cpu {
  final String model;
  final int cores;
  final int physicalCores;
  final int maxSpeedGhz;

  Cpu({
    required this.model,
    required this.cores,
    required this.physicalCores,
    required this.maxSpeedGhz,
  });

  factory Cpu.fromJson(Map<String, dynamic> json) {
    return Cpu(
      model: json['model'],
      cores: json['cores'],
      physicalCores: json['physical_cores'],
      maxSpeedGhz: json['max_speed_ghz'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'model': model,
      'cores': cores,
      'physical_cores': physicalCores,
      'max_speed_ghz': maxSpeedGhz,
    };
  }
}

class Memory {
  final double totalGb;
  final double usedGb;
  final double freeGb;

  Memory({
    required this.totalGb,
    required this.usedGb,
    required this.freeGb,
  });

  factory Memory.fromJson(Map<String, dynamic> json) {
    return Memory(
      totalGb: json['total_gb'],
      usedGb: json['used_gb'],
      freeGb: json['free_gb'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_gb': totalGb,
      'used_gb': usedGb,
      'free_gb': freeGb,
    };
  }
}

class Disk {
  final String drive;
  final double total;
  final double used;
  final double available;

  Disk({
    required this.drive,
    required this.total,
    required this.used,
    required this.available,
  });

  factory Disk.fromJson(Map<String, dynamic> json) {
    return Disk(
      drive: json['drive'],
      total: json['total'],
      used: json['used'],
      available: json['available'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'drive': drive,
      'total': total,
      'used': used,
      'available': available,
    };
  }
}

class System {
  final String type;
  final String touchSupport;

  System({
    required this.type,
    required this.touchSupport,
  });

  factory System.fromJson(Map<String, dynamic> json) {
    return System(
      type: json['type'],
      touchSupport: json['touch_support'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'touch_support': touchSupport,
    };
  }
}