class Tag {
  String name;
  String color;

  Tag({required this.name, required this.color});

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'color': color,
    };
  }

  // 可以添加从Map转换回Tag对象的工厂方法
  factory Tag.fromMap(Map<String, dynamic> map) {
    return Tag(
      name: map['name'],
      color: map['color'],
    );
  }
}
