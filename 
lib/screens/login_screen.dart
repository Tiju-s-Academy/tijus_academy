    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // Phone validation
  String? _validatePhone(String? value) {
    if (!_isLoginMode && (value == null || value.isEmpty)) {
      return 'Phone number is required';
    }
    if (!_isLoginMode && value != null) {
      // Basic phone validation - allow digits, +, -, spaces, and min 10 digits
      final phoneRegex = RegExp(r'^\+?[\d\s-]{10,}$');
      if (!phoneRegex.hasMatch(value)) {
        return 'Enter a valid phone number';
      }
    }
    return null;
  }
        await authProvider.register(
          _emailController.text.trim(),
          _passwordController.text,
          _nameController.text.trim(),
          _phoneController.text.trim(),
        );
                      const SizedBox(height: 16),
                      
                      // Phone number field
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          prefixIcon: Icon(Icons.phone),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: _validatePhone,
                        enabled: !_isLoading,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                
                // Email field
