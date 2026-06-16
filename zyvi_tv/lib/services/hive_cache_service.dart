import 'package:hive/hive.dart';
import '../data/models/channel_model.dart';

class HiveCacheService {
  static const String channelsBoxName = 'channelsBox';
  static const String configBoxName = 'configBox';

  Box<ChannelModel>? _channelsBox;
  Box? _configBox;

  Future<void> init() async {
    _channelsBox = await Hive.openBox<ChannelModel>(channelsBoxName);
    _configBox = await Hive.openBox(configBoxName);
  }

  Box<ChannelModel> get channelsBox {
    if (_channelsBox == null) {
      throw StateError('HiveCacheService not initialized');
    }
    return _channelsBox!;
  }

  Box get configBox {
    if (_configBox == null) {
      throw StateError('HiveCacheService not initialized');
    }
    return _configBox!;
  }

  List<ChannelModel> getCachedChannels() {
    return channelsBox.values.toList();
  }

  Future<void> cacheChannels(List<ChannelModel> channels) async {
    await channelsBox.clear();
    final map = {for (final c in channels) c.id: c};
    await channelsBox.putAll(map);
  }

  int get lastUpdatedTimestamp {
    return configBox.get('last_updated', defaultValue: 0) as int;
  }

  set lastUpdatedTimestamp(int ts) {
    configBox.put('last_updated', ts);
  }

  int getCachedChannelCount() {
    return channelsBox.length;
  }
}
