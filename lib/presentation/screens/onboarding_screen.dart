import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../bloc/settings/settings_bloc.dart';
import '../bloc/settings/settings_event.dart';
import '../bloc/settings/settings_state.dart';
import '../theme/executive_theme.dart';
import 'home_screen.dart';

/// Premium onboarding experience for executives.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _apiKeyController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isObscured = true;
  final _pageController = PageController();

  @override
  void dispose() {
    _apiKeyController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _verifyAndContinue() {
    if (_formKey.currentState?.validate() ?? false) {
      context
          .read<SettingsBloc>()
          .add(VerifyApiKey(_apiKeyController.text.trim()));
    }
  }

  void _navigateToHome() {
    context.read<SettingsBloc>().add(CompleteOnboarding());
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  Future<void> _launchOpenRouterKeys() async {
    final uri = Uri.parse('https://openrouter.ai/settings/keys');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<SettingsBloc, SettingsState>(
        listener: (context, state) {
          if (state is ApiKeyValid) {
            _navigateToHome();
          } else if (state is ApiKeyInvalid) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: ExecutiveTheme.errorColor,
              ),
            );
          }
        },
        child: SafeArea(
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildWelcomePage(),
              _buildApiKeyPage(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo/Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: ExecutiveTheme.goldAccent.withOpacity(0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Image.asset(
                'assets/icons/app_icon.png',
                width: 120,
                height: 120,
              ),
            ),
          ).animate().fadeIn(duration: 600.ms).scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1, 1),
                duration: 600.ms,
                curve: Curves.easeOutBack,
              ),

          const SizedBox(height: 48),

          // Title
          Text(
            'LLM Council',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ).animate().fadeIn(delay: 200.ms, duration: 500.ms),

          const SizedBox(height: 16),

          // Subtitle
          Text(
            'Collective AI wisdom at your fingertips',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: ExecutiveTheme.textSecondary,
                ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 400.ms, duration: 500.ms),

          const SizedBox(height: 64),

          // Features list
          _buildFeatureItem(
            Icons.psychology,
            'Multiple AI Perspectives',
            'Query the top AI models simultaneously',
            delay: 500,
          ),
          const SizedBox(height: 20),
          _buildFeatureItem(
            Icons.rate_review,
            'Peer Review & Ranking',
            'Models evaluate each other\'s responses',
            delay: 600,
          ),
          const SizedBox(height: 20),
          _buildFeatureItem(
            Icons.gavel,
            'Chairman Synthesis',
            'A synthesized answer from collective wisdom',
            delay: 700,
          ),

          const Spacer(),

          // Continue button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _pageController.nextPage(
                duration: 400.ms,
                curve: Curves.easeInOut,
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text('Get Started'),
              ),
            ),
          ).animate().fadeIn(delay: 800.ms, duration: 500.ms).slideY(
                begin: 0.2,
                end: 0,
                delay: 800.ms,
                duration: 500.ms,
              ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String subtitle,
      {int delay = 0}) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: ExecutiveTheme.surfaceColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: ExecutiveTheme.goldAccent, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: delay), duration: 400.ms)
        .slideX(
          begin: 0.1,
          end: 0,
          delay: Duration(milliseconds: delay),
          duration: 400.ms,
        );
  }

  Widget _buildApiKeyPage() {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        final isVerifying = state is ApiKeyVerifying;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),

                // Back button
                IconButton(
                  onPressed: () => _pageController.previousPage(
                    duration: 400.ms,
                    curve: Curves.easeInOut,
                  ),
                  icon: const Icon(Icons.arrow_back),
                  style: IconButton.styleFrom(
                    backgroundColor: ExecutiveTheme.surfaceColor,
                  ),
                ),

                const SizedBox(height: 40),

                // Title
                Text(
                  'Connect to OpenRouter',
                  style: Theme.of(context).textTheme.displaySmall,
                ),

                const SizedBox(height: 12),

                Text(
                  'Enter your OpenRouter API key to access premium AI models. Your key is stored securely on-device.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: ExecutiveTheme.textSecondary,
                      ),
                ),

                const SizedBox(height: 40),

                // API Key input
                TextFormField(
                  controller: _apiKeyController,
                  obscureText: _isObscured,
                  decoration: InputDecoration(
                    labelText: 'API Key',
                    hintText: 'sk-or-v1-...',
                    prefixIcon: const Icon(Icons.key),
                    suffixIcon: IconButton(
                      icon: Icon(_isObscured
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () =>
                          setState(() => _isObscured = !_isObscured),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your API key';
                    }
                    if (!value.startsWith('sk-or-')) {
                      return 'Invalid OpenRouter API key format';
                    }
                    return null;
                  },
                  inputFormatters: [
                    FilteringTextInputFormatter.deny(RegExp(r'\s')),
                  ],
                ),

                const SizedBox(height: 16),

                // Info card - tappable to open browser
                GestureDetector(
                  onTap: () => _launchOpenRouterKeys(),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: ExecutiveTheme.goldAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: ExecutiveTheme.goldAccent.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: ExecutiveTheme.goldAccent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.open_in_new,
                            color: ExecutiveTheme.goldAccent,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Get your API key',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      color: ExecutiveTheme.goldAccent,
                                    ),
                              ),
                              Text(
                                'Tap to open openrouter.ai',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: ExecutiveTheme.goldAccent,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Continue button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isVerifying ? null : _verifyAndContinue,
                    child: isVerifying
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: ExecutiveTheme.primaryBackground,
                            ),
                          )
                        : const Text('Verify & Continue'),
                  ),
                ),

                const SizedBox(height: 16),

                // Skip option
                Center(
                  child: TextButton(
                    onPressed: _navigateToHome,
                    child: const Text('Skip for now'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
