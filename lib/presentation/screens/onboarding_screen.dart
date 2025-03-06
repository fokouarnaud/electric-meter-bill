// lib/presentation/screens/onboarding_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/common_widgets.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 4;
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Bouton "Passer"
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _completeOnboarding,
                child: Text(l10n?.skip ?? 'Skip'),
              ),
            ),
            
            // Pages du tutoriel
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                children: [
                  _buildOnboardingPage(
                    title: l10n?.onboardingTitle1 ?? 'Welcome!',
                    description: l10n?.onboardingDesc1 ?? 
                      'This app helps you manage your electric meters and easily create bills.',
                    icon: Icons.electric_meter,
                  ),
                  _buildOnboardingPage(
                    title: l10n?.onboardingTitle2 ?? 'Add your meters',
                    description: l10n?.onboardingDesc2 ?? 
                      'Start by adding one or more meters with basic information.',
                    icon: Icons.add_circle,
                  ),
                  _buildOnboardingPage(
                    title: l10n?.onboardingTitle3 ?? 'Take meter readings',
                    description: l10n?.onboardingDesc3 ?? 
                      'Take a photo of your meter to automatically record its value.',
                    icon: Icons.camera_alt,
                  ),
                  _buildOnboardingPage(
                    title: l10n?.onboardingTitle4 ?? 'Generate bills',
                    description: l10n?.onboardingDesc4 ?? 
                      'Create bills based on your readings and send them via email or SMS.',
                    icon: Icons.receipt_long,
                  ),
                ],
              ),
            ),
            
            // Indicateurs de page
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _totalPages,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  width: index == _currentPage ? 16 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: index == _currentPage
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey[300],
                  ),
                ),
              ),
            ),
            
            // Boutons de navigation
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage > 0)
                    TextButton.icon(
                      icon: const Icon(Icons.arrow_back),
                      label: Text(l10n?.previous ?? 'Previous'),
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                    )
                  else
                    const SizedBox.shrink(),
                  
                  ElevatedButton.icon(
                    icon: Icon(_currentPage < _totalPages - 1
                        ? Icons.arrow_forward
                        : Icons.check),
                    label: Text(_currentPage < _totalPages - 1
                        ? (l10n?.next ?? 'Next')
                        : (l10n?.getStarted ?? 'Get Started')),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 12.0,
                      ),
                    ),
                    onPressed: () {
                      if (_currentPage < _totalPages - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        _completeOnboarding();
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildOnboardingPage({
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CommonWidgets.buildPulseAnimation(
            child: Icon(
              icon,
              size: 120,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Future<void> _completeOnboarding() async {
    // Marquer l'onboarding comme terminé
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    
    // Navigate to the home screen
    if (context.mounted) {
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (context) => const HomeScreen()),
      );
    }
  }
}