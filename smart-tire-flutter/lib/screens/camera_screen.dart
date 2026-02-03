import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isFlashOn = false;
  bool _isInitialized = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _requestPermissionsAndInitialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _requestPermissionsAndInitialize() async {
    final cameraStatus = await Permission.camera.request();
    
    if (cameraStatus.isGranted) {
      await _initializeCamera();
    } else if (cameraStatus.isDenied) {
      setState(() {
        _errorMessage = 'กรุณาอนุญาตการใช้กล้อง';
      });
    } else if (cameraStatus.isPermanentlyDenied) {
      setState(() {
        _errorMessage = 'กรุณาเปิดการใช้กล้องในการตั้งค่า';
      });
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _errorMessage = 'ไม่พบกล้อง';
        });
        return;
      }

      // หากล้องหลัง
      final backCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras![0],
      );

      print('Initializing camera: ${backCamera.name}');

      _controller = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      
      // ตั้งค่า flash mode เริ่มต้นเป็น off
      await _controller!.setFlashMode(FlashMode.off);
      print('Camera initialized successfully');
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isFlashOn = false;
        });
      }
    } catch (e) {
      print('Error initializing camera: $e');
      setState(() {
        _errorMessage = 'เกิดข้อผิดพลาดในการเปิดกล้อง';
      });
    }
  }

  Future<void> _toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      print('Controller not initialized');
      return;
    }

    try {
      setState(() {
        _isFlashOn = !_isFlashOn;
      });
      
      final newMode = _isFlashOn ? FlashMode.always : FlashMode.off;
      print('Setting flash mode to: $newMode');
      
      await _controller!.setFlashMode(newMode);
      print('Flash mode set successfully');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isFlashOn ? 'เปิดแฟลช' : 'ปิดแฟลช'),
            duration: const Duration(milliseconds: 500),
            backgroundColor: _isFlashOn 
                ? const Color(0xFFFFD700) 
                : Colors.grey[800],
          ),
        );
      }
      
    } catch (e) {
      print('Error toggling flash: $e');
      // revert state ถ้า error
      setState(() {
        _isFlashOn = !_isFlashOn;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ไม่สามารถเปิด/ปิดแฟลชได้: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      print('Controller not ready');
      return;
    }

    if (_controller!.value.isTakingPicture) {
      print('Already taking picture');
      return;
    }

    try {
      print('=== Taking Picture ===');
      print('Flash is ON: $_isFlashOn');
      print('Current flash mode: ${_controller!.value.flashMode}');
      
      // ตรวจสอบและตั้งค่า flash mode อีกครั้งก่อนถ่าย
      final expectedMode = _isFlashOn ? FlashMode.always : FlashMode.off;
      if (_controller!.value.flashMode != expectedMode) {
        print('Flash mode mismatch! Setting to: $expectedMode');
        await _controller!.setFlashMode(expectedMode);
        // รอให้ตั้งค่าเสร็จ
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      final XFile image = await _controller!.takePicture();
      print('Picture taken successfully: ${image.path}');
      
      if (!mounted) return;
      
      Navigator.pop(context, File(image.path));
      
    } catch (e) {
      print('Error taking picture: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ไม่สามารถถ่ายรูปได้: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 64,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => openAppSettings(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                      minimumSize: const Size(200, 50),
                    ),
                    child: const Text(
                      'เปิดการตั้งค่า',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'ยกเลิก',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (!_isInitialized || _controller == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFFFFD700)),
              SizedBox(height: 16),
              Text(
                'กำลังเปิดกล้อง...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera Preview
          Center(
            child: CameraPreview(_controller!),
          ),

          // Top Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Close Button
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, size: 32),
                      color: Colors.white,
                    ),
                    
                    // Flash Button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _toggleFlash,
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: _isFlashOn
                                ? const Color(0xFFFFD700).withOpacity(0.3)
                                : Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: _isFlashOn
                                  ? const Color(0xFFFFD700)
                                  : Colors.white.withOpacity(0.7),
                              width: 2.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isFlashOn ? Icons.flash_on : Icons.flash_off,
                                color: _isFlashOn
                                    ? const Color(0xFFFFD700)
                                    : Colors.white,
                                size: 26,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isFlashOn ? 'เปิด' : 'ปิด',
                                style: TextStyle(
                                  color: _isFlashOn
                                      ? const Color(0xFFFFD700)
                                      : Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Flash Status Indicator (Debug)
          if (_isFlashOn)
            Positioned(
              top: 80,
              right: 20,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.flash_on, size: 16, color: Colors.black),
                      SizedBox(width: 4),
                      Text(
                        'แฟลชเปิดอยู่',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Bottom Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 40),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Center(
                  child: GestureDetector(
                    onTap: _takePicture,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _isFlashOn 
                              ? const Color(0xFFFFD700)
                              : Colors.white,
                          width: 6,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isFlashOn 
                                ? const Color(0xFFFFD700)
                                : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}