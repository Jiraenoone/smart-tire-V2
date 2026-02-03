import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/tire_data.dart';
import '../services/tire_api_service.dart';
import 'package:uuid/uuid.dart';
import 'camera_screen.dart';

class AddTireScreen extends StatefulWidget {
  final String position;

  const AddTireScreen({Key? key, required this.position}) : super(key: key);

  @override
  State<AddTireScreen> createState() => _AddTireScreenState();
}

class _AddTireScreenState extends State<AddTireScreen> {
  int _currentStep = 0;
  File? _sidewallImage;
  File? _treadImage;

  String? _serialNumber;
  String? _dotCode;
  DateTime? _manufactureDate;
  double? _treadDepth;

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('เพิ่มข้อมูลยาง - ${_getPositionText(widget.position)}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
                  ),
                  SizedBox(height: 16),
                  Text('กำลังประมวลผล...',
                      style: TextStyle(color: Colors.white70)),
                ],
              ),
            )
          : _buildCurrentStep(),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildSidewallInstructionStep();
      case 1:
        return _buildCameraStep(true);
      case 2:
        return _buildSidewallResultStep();
      case 3:
        return _buildTreadInstructionStep();
      case 4:
        return _buildCameraStep(false);
      case 5:
        return _buildCompletionStep();
      default:
        return Container();
    }
  }

  Widget _buildSidewallInstructionStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'วิธีการถ่ายรูปแก้มยาง',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFD700),
            ),
          ),
          const SizedBox(height: 32),
          Container(
            height: 300,
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFD700), width: 2),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image, size: 80, color: Color(0xFFFFD700)),
                  SizedBox(height: 16),
                  Text(
                    'ตัวอย่างการถ่ายแก้มยาง',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '• ถ่ายให้เห็นข้อมูลบนแก้มยางชัดเจน\n• รวม DOT Code, รุ่นยาง, ขนาดยาง\n• หลีกเลี่ยงแสงสะท้อน',
            style: TextStyle(color: Colors.white70, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () => setState(() => _currentStep = 1),
            style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50)),
            child: const Text('ถัดไป'),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraStep(bool isSidewall) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            isSidewall ? 'ถ่ายรูปแก้มยาง' : 'ถ่ายรูปดอกยาง',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFD700),
            ),
          ),
          const SizedBox(height: 32),
          if ((isSidewall ? _sidewallImage : _treadImage) != null)
            Container(
              height: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                  image: FileImage(isSidewall ? _sidewallImage! : _treadImage!),
                  fit: BoxFit.cover,
                ),
              ),
            )
          else
            Container(
              height: 300,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFD700), width: 2),
              ),
              child: const Center(
                child:
                    Icon(Icons.camera_alt, size: 80, color: Color(0xFFFFD700)),
              ),
            ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera, isSidewall),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('ถ่ายรูป'),
                  style:
                      ElevatedButton.styleFrom(minimumSize: const Size(0, 50)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery, isSidewall),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('แกลลอรี่'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 50),
                    backgroundColor: const Color(0xFF2A2A2A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if ((isSidewall ? _sidewallImage : _treadImage) != null)
            ElevatedButton(
              onPressed: () => _processImage(isSidewall),
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50)),
              child: const Text('ยืนยัน'),
            ),
        ],
      ),
    );
  }

  Widget _buildSidewallResultStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text(
            'ข้อมูลจากแก้มยาง',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFD700),
            ),
          ),
          const SizedBox(height: 32),
          _buildInfoCard('เลขซีเรียส', _serialNumber ?? 'ไม่ระบุ'),
          _buildInfoCard('DOT Code', _dotCode ?? 'ไม่ระบุ'),
          _buildInfoCard(
              'วันที่ผลิต',
              _manufactureDate != null
                  ? '${_manufactureDate!.day}/${_manufactureDate!.month}/${_manufactureDate!.year + 543}'
                  : 'ไม่ระบุ'),
          const Spacer(),
          ElevatedButton(
            onPressed: () => setState(() => _currentStep = 3),
            style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50)),
            child: const Text('ถัดไป'),
          ),
        ],
      ),
    );
  }

  Widget _buildTreadInstructionStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'วิธีการวัดความลึกดอกยาง',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFD700),
            ),
          ),
          const SizedBox(height: 32),
          Container(
            height: 300,
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFD700), width: 2),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image, size: 80, color: Color(0xFFFFD700)),
                  SizedBox(height: 16),
                  Text(
                    'ตัวอย่างการวัดดอกยาง',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '• ถ่ายให้เห็นดอกยางชัดเจน\n• วางเหรียญหรือไม้บรรทัดเพื่ออ้างอิง\n• ถ่ายตรงจากด้านบน',
            style: TextStyle(color: Colors.white70, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () => setState(() => _currentStep = 4),
            style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50)),
            child: const Text('ถัดไป'),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle,
            size: 100,
            color: Colors.green,
          ),
          const SizedBox(height: 24),
          const Text(
            'บันทึกข้อมูลเรียบร้อย',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFD700),
            ),
          ),
          const SizedBox(height: 32),
          _buildInfoCard(
              'ความลึกดอกยาง', '${_treadDepth?.toStringAsFixed(1) ?? '0'} mm'),
          _buildInfoCard('กิโลเมตรที่เหลือโดยประมาณ',
              '${((_treadDepth ?? 0) * 4000).toStringAsFixed(0)} km'),
          const Spacer(),
          ElevatedButton(
            onPressed: _saveTireData,
            style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50)),
            child: const Text('เสร็จสิ้น'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color.fromRGBO(255, 215, 0, 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source, bool isSidewall) async {
    File? imageFile;

    if (source == ImageSource.camera) {
      // ใช้กล้องแบบกำหนดเองที่มี flash
      imageFile = await Navigator.push<File>(
        context,
        MaterialPageRoute(builder: (context) => const CameraScreen()),
      );
    } else {
      // ใช้ gallery ปกติ
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null) {
        imageFile = File(pickedFile.path);
      }
    }

    if (imageFile != null) {
      setState(() {
        if (isSidewall) {
          _sidewallImage = imageFile;
        } else {
          _treadImage = imageFile;
        }
      });
    }
  }

  Future<void> _processImage(bool isSidewall) async {
    setState(() => _isLoading = true);

    try {
      final apiService = TireApiService();

      if (isSidewall) {
        var result = await apiService.analyzeSidewall(_sidewallImage!);

        if (result['success']) {
          var data = result['data'];
          setState(() {
            _serialNumber = data['serialNumber'] ?? 'ไม่ระบุ';
            _dotCode = data['dotCode'] ?? 'ไม่ระบุ';
            _manufactureDate = TireApiService.parseDotCode(_dotCode ?? '');
            _currentStep = 2;
          });
        } else {
          _showError(result['error']);
        }
      } else {
        var result = await apiService.measureTreadDepth(_treadImage!);

        if (result['success']) {
          var data = result['data'];
          setState(() {
            _treadDepth = (data['treadDepth'] ?? 0).toDouble();
            _currentStep = 5;
          });
        } else {
          _showError(result['error']);
        }
      }
    } catch (e) {
      _showError('เกิดข้อผิดพลาด: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _saveTireData() async {
    if (_treadDepth == null) {
      _showError('ข้อมูลไม่ครบถ้วน');
      return;
    }

    final tireData = TireData(
      id: const Uuid().v4(),
      serialNumber: _serialNumber ?? '',
      dotCode: _dotCode ?? '',
      manufactureDate: _manufactureDate ?? DateTime.now(),
      treadDepth: _treadDepth!,
      sidewallImagePath: _sidewallImage?.path ?? '',
      treadImagePath: _treadImage?.path ?? '',
      lastUpdated: DateTime.now(),
    );

    if (!mounted) return;
    final appState = Provider.of<AppState>(context, listen: false);
    await appState.updateTireData(widget.position, tireData);

    if (!mounted) return;
    Navigator.pop(context);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  String _getPositionText(String position) {
    switch (position) {
      case 'FL':
        return 'หน้าซ้าย';
      case 'FR':
        return 'หน้าขวา';
      case 'RL':
        return 'หลังซ้าย';
      case 'RR':
        return 'หลังขวา';
      case 'SPARE':
        return 'อะไหล่';
      default:
        return position;
    }
  }
}
