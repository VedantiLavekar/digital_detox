import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login.dart';
import 'user_model.dart';
import 'database_helper.dart';

const Color kPrimaryColor = Color(0xFF2E9D8A);
const Color kBackgroundColor = Color(0xFFF5F5DC);

enum Gender { male, female, other, undisclosed }

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Controllers for all steps
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // State variables
  String? nameError;
  String? phoneError;
  String? emailError;
  String? dobError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _genderError;
  String? _screenTimeError;

  int? _age;
  Gender? _selectedGender;
  double _screenTime = 2.0;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isPasswordValid = false;
  bool _isConfirmValid = false;

  // Step 1 Validations
  bool isValidName(String name) =>
      RegExp(r"^[A-Za-z]+(?: [A-Za-z]+)+$").hasMatch(name.trim());

  bool isValidPhone(String phone) =>
      RegExp(r'^[0-9]{10}$').hasMatch(phone.trim());

  void validateStep1() {
    setState(() {
      nameError = _nameController.text.trim().isEmpty
          ? 'Full name is required'
          : (!isValidName(_nameController.text)
                ? 'Enter first and last name (alphabets only)'
                : null);

      phoneError = _phoneController.text.trim().isEmpty
          ? 'Phone number is required'
          : (!isValidPhone(_phoneController.text)
                ? 'Enter a valid 10-digit number'
                : null);
    });
  }

  // Step 2 Validations
  bool isValidEmail(String e) =>
      RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$").hasMatch(e.trim());

  bool isValidDOB(DateTime dob) {
    final today = DateTime.now();
    int age = _calculateAge(dob);
    return dob.isBefore(today) && age >= 13;
  }

  int _calculateAge(DateTime dob) {
    final today = DateTime.now();
    int age = today.year - dob.year;
    if (today.month < dob.month ||
        (today.month == dob.month && today.day < dob.day)) {
      age--;
    }
    return age;
  }

  void _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: kPrimaryColor,
              onPrimary: Colors.white,
              onSurface: kPrimaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formatted = DateFormat('dd/MM/yyyy').format(picked);
      _dobController.text = formatted;
      _age = _calculateAge(picked);
      _validateStep2();
    }
  }

  void _validateStep2() {
    setState(() {
      emailError = _emailController.text.trim().isEmpty
          ? 'Email is required'
          : (!isValidEmail(_emailController.text)
                ? 'Enter a valid email address'
                : null);

      if (_dobController.text.trim().isEmpty) {
        dobError = 'Date of birth is required';
      } else {
        try {
          DateTime dob = DateFormat('dd/MM/yyyy').parse(_dobController.text);
          dobError = !isValidDOB(dob) ? 'Age must be at least 13 years' : null;
        } catch (e) {
          dobError = 'Invalid date format';
        }
      }
    });
  }

  // Step 3 Validations
  void _validateStep3() {
    setState(() {
      _genderError = _selectedGender == null ? "Please select a gender" : null;
    });
  }

  // Step 4 Validations
  void _validateStep4(double value) {
    setState(() {
      if (value < 0.5) {
        _screenTimeError = "Screen time must be at least 0.5 hours";
      } else if (value > 12.0) {
        _screenTimeError = "Screen time cannot exceed 12 hours";
      } else {
        _screenTimeError = null;
      }
    });
  }

  // Step 5 Validations
  bool _validatePassword(String password) {
    final hasUpper = password.contains(RegExp(r'[A-Z]'));
    final hasLower = password.contains(RegExp(r'[a-z]'));
    final hasDigit = password.contains(RegExp(r'[0-9]'));
    final hasSpecial = password.contains(RegExp(r'[!@#\$&*~]'));
    final looksLikeEmail = password.contains('@') && password.contains('.');

    return hasUpper &&
        hasLower &&
        hasDigit &&
        hasSpecial &&
        password.length >= 8 &&
        !looksLikeEmail;
  }

  void _onPasswordChanged(String password) {
    setState(() {
      _isPasswordValid = _validatePassword(password);

      if (password.isEmpty) {
        _passwordError = 'Password is required';
      } else if (!_isPasswordValid) {
        _passwordError =
            'Password must contain uppercase, lowercase, number, special character, and be 8+ characters';
      } else {
        _passwordError = null;
      }

      if (_confirmPasswordController.text.isNotEmpty) {
        _onConfirmChanged(_confirmPasswordController.text);
      }
    });
  }

  void _onConfirmChanged(String confirm) {
    setState(() {
      if (confirm.isEmpty) {
        _confirmPasswordError = 'Confirm password is required';
        _isConfirmValid = false;
      } else if (confirm != _passwordController.text) {
        _confirmPasswordError = 'Passwords do not match';
        _isConfirmValid = false;
      } else {
        _confirmPasswordError = null;
        _isConfirmValid = true;
      }
    });
  }

  Future<void> _signUp() async {
    if (!_isPasswordValid || !_isConfirmValid) return;


    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(color: kPrimaryColor),
          );
        },
      );

      // Create user profile
      UserProfile userProfile = UserProfile(
        fullName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        dateOfBirth: _dobController.text.trim(),
        age: _age ?? 0,
        gender: _selectedGender.toString().split('.').last,
        screenTimeLimit: _screenTime,
        password: _passwordController.text,
      );

      // Save to local database first
      DatabaseHelper dbHelper = DatabaseHelper();
      await dbHelper.createUser(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        userProfile: userProfile,
      );

      // Try Firebase Auth (with fallback)
      try {
        print(
          '🔵 Starting Firebase signup for: ${_emailController.text.trim()}',
        );
        print('🔵 Password length: ${_passwordController.text.length}');

        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            );

        print('🟢 Firebase Auth successful! UID: ${userCredential.user!.uid}');

        if (userCredential.user != null) {
          final firestoreData = {
            ...userProfile.toFirestore(),
            'uid': userCredential.user!.uid,
            'createdAt': FieldValue.serverTimestamp(),
            'lastLogin': FieldValue.serverTimestamp(),
            'accountStatus': 'active',
          };

          print(
            '🔵 Saving to Firestore collection: users/${userCredential.user!.uid}',
          );
          print('🔵 Data to save: $firestoreData');

          // Save user profile to Firestore with metadata
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userCredential.user!.uid)
              .set(firestoreData);

          print('✅ User profile saved to Firestore successfully!');
          print(
            '✅ Check Firebase Console: https://console.firebase.google.com/u/0/project/digital-detox-d738f/firestore/databases/-default-/data',
          );

          // Initialize empty detox sessions collection for this user
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userCredential.user!.uid)
              .collection('detoxSessions')
              .doc('_initialized')
              .set({
                'initialized': true,
                'timestamp': FieldValue.serverTimestamp(),
              });

          print(
            '✅ User data fully saved to Firestore: ${userCredential.user!.uid}',
          );
        }
      } catch (firebaseError) {
        // Firebase failed, but local database succeeded
        print('❌ Firebase error: $firebaseError');
        print('❌ Error type: ${firebaseError.runtimeType}');
        if (firebaseError is FirebaseAuthException) {
          print('❌ Firebase Auth Error Code: ${firebaseError.code}');
          print('❌ Firebase Auth Error Message: ${firebaseError.message}');
        }
      }

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show success message and navigate to login page
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Registration successful! Please log in to continue.',
            ),
            backgroundColor: kPrimaryColor,
          ),
        );
        // Sign out the user so they have to login again (as per user requirement)
        await FirebaseAuth.instance.signOut();
        // Navigate to login page
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      String errorMessage;
      switch (e.code) {
        case 'configuration-not-found':
          errorMessage =
              'Firebase configuration error. Please try again later.';
          break;
        case 'email-already-in-use':
          errorMessage = 'An account already exists with this email.';
          break;
        case 'weak-password':
          errorMessage = 'Password is too weak.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address.';
          break;
        default:
          errorMessage = e.message ?? 'Registration failed. Please try again.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An unexpected error occurred: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _nextPage() {
    if (_currentPage < 4) {
      bool canProceed = false;

      switch (_currentPage) {
        case 0:
          validateStep1();
          canProceed = nameError == null && phoneError == null;
          break;
        case 1:
          _validateStep2();
          canProceed = emailError == null && dobError == null;
          break;
        case 2:
          _validateStep3();
          canProceed = _genderError == null;
          break;
        case 3:
          _validateStep4(_screenTime);
          canProceed = _screenTimeError == null;
          break;
      }

      if (canProceed) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fix errors before proceeding')),
        );
      }
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _validateStep4(_screenTime);

    // Add listeners for real-time validation
    _nameController.addListener(() {
      if (nameError != null) validateStep1();
    });
    _phoneController.addListener(() {
      if (phoneError != null) validateStep1();
    });
    _emailController.addListener(() {
      if (emailError != null) _validateStep2();
    });
    _passwordController.addListener(() {
      _onPasswordChanged(_passwordController.text);
    });
    _confirmPasswordController.addListener(() {
      _onConfirmChanged(_confirmPasswordController.text);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: List.generate(5, (index) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: index <= _currentPage
                            ? kPrimaryColor
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics:
                    const NeverScrollableScrollPhysics(), // Prevent horizontal scrolling conflicts
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  _buildScrollableStep(_buildStep1()), // Name and Phone
                  _buildScrollableStep(_buildStep2()), // Email and DOB
                  _buildScrollableStep(_buildStep3()), // Gender
                  _buildScrollableStep(_buildStep4()), // Screen Time
                  _buildScrollableStep(_buildStep5()), // Password
                ],
              ),
            ),

            // Navigation buttons
            Container(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousPage,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: kPrimaryColor),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Back',
                          style: TextStyle(
                            color: kPrimaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  if (_currentPage > 0) const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _currentPage == 4 ? _signUp : _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        _currentPage == 4 ? 'Sign Up' : 'Next',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to make each step scrollable when keyboard appears
  Widget _buildScrollableStep(Widget step) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: step,
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 48),
        Center(
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.person, size: 60, color: Colors.grey),
            ),
          ),
        ),
        const SizedBox(height: 48),

        TextField(
          controller: _nameController,
          style: const TextStyle(
            color: kPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            labelText: 'Full Name',
            labelStyle: const TextStyle(
              color: kPrimaryColor,
              fontWeight: FontWeight.bold,
            ),
            border: const OutlineInputBorder(),
            errorText: nameError,
          ),
        ),
        const SizedBox(height: 24),

        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          style: const TextStyle(
            color: kPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            labelText: 'Phone Number',
            labelStyle: const TextStyle(
              color: kPrimaryColor,
              fontWeight: FontWeight.bold,
            ),
            border: const OutlineInputBorder(),
            errorText: phoneError,
          ),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 48),
        Center(
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.email, size: 60, color: Colors.grey),
            ),
          ),
        ),
        const SizedBox(height: 48),

        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(
            color: kPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            labelText: 'Email Address',
            labelStyle: const TextStyle(
              color: kPrimaryColor,
              fontWeight: FontWeight.bold,
            ),
            border: const OutlineInputBorder(),
            errorText: emailError,
          ),
        ),
        const SizedBox(height: 24),

        TextField(
          controller: _dobController,
          readOnly: true,
          onTap: _pickDate,
          style: const TextStyle(
            color: kPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            labelText: 'Date of Birth (DD/MM/YYYY)',
            labelStyle: const TextStyle(
              color: kPrimaryColor,
              fontWeight: FontWeight.bold,
            ),
            border: const OutlineInputBorder(),
            suffixIcon: const Icon(Icons.calendar_today, color: kPrimaryColor),
            errorText: dobError,
          ),
        ),
        if (_age != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Age: $_age years',
              style: const TextStyle(
                color: kPrimaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 48),
        Center(
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.person, size: 60, color: Colors.grey),
            ),
          ),
        ),
        const SizedBox(height: 48),

        const Text(
          'Select Gender',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: kPrimaryColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        ...Gender.values.map((gender) {
          String displayName =
              gender.name[0].toUpperCase() + gender.name.substring(1);
          if (gender == Gender.undisclosed) displayName = 'Prefer not to say';

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: RadioListTile<Gender>(
              title: Text(
                displayName,
                style: const TextStyle(
                  color: kPrimaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              value: gender,
              groupValue: _selectedGender,
              activeColor: kPrimaryColor,
              onChanged: (Gender? value) {
                setState(() {
                  _selectedGender = value;
                  _genderError = null;
                });
              },
            ),
          );
        }),

        if (_genderError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              _genderError!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildStep4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 48),
        Center(
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.access_time, size: 60, color: Colors.grey),
            ),
          ),
        ),
        const SizedBox(height: 48),

        const Text(
          'Daily Screen Time Limit',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: kPrimaryColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        Text(
          '${_screenTime.toStringAsFixed(1)} hours per day',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: kPrimaryColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        Slider(
          value: _screenTime,
          min: 0.5,
          max: 12.0,
          divisions: 23,
          activeColor: kPrimaryColor,
          inactiveColor: Colors.grey[300],
          onChanged: (value) {
            setState(() {
              _screenTime = value;
            });
            _validateStep4(value);
          },
        ),

        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('0.5h', style: TextStyle(color: kPrimaryColor)),
            Text('12h', style: TextStyle(color: kPrimaryColor)),
          ],
        ),

        if (_screenTimeError != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              _screenTimeError!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  Widget _buildStep5() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 48),
        Center(
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.lock, size: 60, color: Colors.grey),
            ),
          ),
        ),
        const SizedBox(height: 48),

        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: const TextStyle(
            color: kPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            labelText: 'Password',
            labelStyle: const TextStyle(
              color: kPrimaryColor,
              fontWeight: FontWeight.bold,
            ),
            border: const OutlineInputBorder(),
            errorText: _passwordError,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                color: kPrimaryColor,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 24),

        TextField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirm,
          style: const TextStyle(
            color: kPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            labelText: 'Confirm Password',
            labelStyle: const TextStyle(
              color: kPrimaryColor,
              fontWeight: FontWeight.bold,
            ),
            border: const OutlineInputBorder(),
            errorText: _confirmPasswordError,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirm ? Icons.visibility : Icons.visibility_off,
                color: kPrimaryColor,
              ),
              onPressed: () {
                setState(() {
                  _obscureConfirm = !_obscureConfirm;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 16),

        const Text(
          'Password Requirements:',
          style: TextStyle(fontWeight: FontWeight.bold, color: kPrimaryColor),
        ),
        const SizedBox(height: 8),

        _buildPasswordRequirement(
          'At least 8 characters',
          _passwordController.text.length >= 8,
        ),
        _buildPasswordRequirement(
          'Uppercase letter',
          _passwordController.text.contains(RegExp(r'[A-Z]')),
        ),
        _buildPasswordRequirement(
          'Lowercase letter',
          _passwordController.text.contains(RegExp(r'[a-z]')),
        ),
        _buildPasswordRequirement(
          'Number',
          _passwordController.text.contains(RegExp(r'[0-9]')),
        ),
        _buildPasswordRequirement(
          'Special character (!@#\$&*~)',
          _passwordController.text.contains(RegExp(r'[!@#\$&*~]')),
        ),
      ],
    );
  }

  Widget _buildPasswordRequirement(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isMet ? Colors.green : Colors.grey,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: isMet ? Colors.green : Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
