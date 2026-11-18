// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/app_header.dart';
import '../../widgets/custom_drawer.dart';
import '../../widgets/search_form.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const AppHeader(hideTitle: true),
      drawer: const CustomDrawer(currentRoute: '/'),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // 1. Hero Section with Dark Gradient & Search Form
              _buildHeroSection(context),

              // 2. Why Choose Twende Section
              _buildWhySection(),

              // 3. Meet Some of Our Car Sizes (Mini, Midi, Maxi)
              _buildCarSizesSection(context),

              // 4. What Makes Us Different (Services)
              _buildServicesSection(),

              // 5. Frequently Asked Questions (FAQ)
              _buildFaqSection(),

              // 7. Customer Care Banner
              _buildCustomerCareSection(context),

              // 8. Footer
              _buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. Hero Section
  // ---------------------------------------------------------------------------
  Widget _buildHeroSection(BuildContext context) {
    return Stack(
      children: [
        // 1. Background Driving Loop (GIF / Sunset video still)
        Positioned.fill(
          child: Image.asset(
            'assets/images/cover.gif',
            fit: BoxFit.cover,
            alignment: Alignment.center,
            errorBuilder: (_, __, ___) => Image.asset(
              'assets/images/cover_sunset.jpg',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder: (_, __, ___) => Container(color: const Color(0xFF1E140E)),
            ),
          ),
        ),

        // 2. Cinematic Soft Gradient Overlay (subtle & light so driving GIF is bright & clearly visible)
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.18),
                  Colors.black.withValues(alpha: 0.45),
                ],
              ),
            ),
          ),
        ),

        // 3. Foreground Content: tall hero (minHeight: 620) with compact search card to maximize background video visibility
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 620),
          padding: const EdgeInsets.fromLTRB(16, 28, 16, 36),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 370),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Standalone Twende® Logo
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Twende',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 5, left: 2),
                        child: Text(
                          '®',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Main Headline
                  const Text(
                    'Book your vehicle today!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      shadows: [
                        Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 1)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),

                  // Subtitle
                  const Text(
                    'Compare fleet options and manage your next move with confidence.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      shadows: [
                        Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 1)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Floating Search Card (compact, sleek & semi-translucent white)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x55000000),
                          blurRadius: 18,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                    child: const SearchForm(isSmall: true),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 2. Why Choose Us Section
  // ---------------------------------------------------------------------------
  Widget _buildWhySection() {
    final features = [
      (
        icon: Icons.room_service_outlined,
        title: '24/7 Roadside Assistance',
        text: 'Round-the-clock roadside service for complete peace of mind.',
      ),
      (
        icon: Icons.visibility_off_outlined,
        title: 'No Hidden Charges',
        text: 'What you see is what you pay. 100% transparent pricing.',
      ),
      (
        icon: Icons.directions_car_outlined,
        title: 'Distinctive Fleet',
        text: 'Choose from a wide selection of premium, reliable vehicles.',
      ),
      (
        icon: Icons.speed_outlined,
        title: 'Unlimited Mileage',
        text: 'Explore cities and beyond without restrictive distance limits.',
      ),
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              const Text(
                'Why Choose Us?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF212121),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Book with us today and drive with confidence!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 28),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: features.map((f) {
                  return Container(
                    width: 360,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.screenBackground,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(f.icon, color: Colors.black, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                f.title,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF212121),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                f.text,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. Meet Some of Our Cars
  // ---------------------------------------------------------------------------
  Widget _buildCarSizesSection(BuildContext context) {
    final cars = [
      'assets/images/mini.png',
      'assets/images/midi.png',
      'assets/images/maxi.png',
    ];

    return Container(
      color: const Color(0xFFF9F9F9),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              const Text(
                'Meet Some of Our Cars',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF212121),
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: cars.map((asset) {
                  return InkWell(
                    onTap: () => context.push('/cars'),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 240,
                      height: 120,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Image.asset(
                          asset,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.directions_car,
                            size: 48,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. What Makes Us Different
  // ---------------------------------------------------------------------------
  Widget _buildServicesSection() {
    final services = [
      (
        icon: Icons.directions_car,
        title: 'Wide Range Of Vehicles',
        desc: 'From compact city hatchbacks to luxury SUVs, our fleet caters to every travel need.',
      ),
      (
        icon: Icons.navigation_outlined,
        title: 'Flexible Pick-Up & Drop-Off',
        desc: 'Convenient airport and downtown locations with flexible scheduling.',
      ),
      (
        icon: Icons.attach_money,
        title: 'Excellent Prices',
        desc: 'Competitive rates and special discounts ensuring unbeatable value every time.',
      ),
      (
        icon: Icons.public,
        title: 'Easy Online Booking',
        desc: 'Skip the counters and reserve your car in minutes through our seamless app.',
      ),
      (
        icon: Icons.flash_on,
        title: 'Instant Booking',
        desc: 'Immediate confirmation with zero waiting or paperwork delays.',
      ),
      (
        icon: Icons.support_agent,
        title: '24/7 Customer Support',
        desc: 'Dedicated assistance available around the clock wherever you travel.',
      ),
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              const Text(
                'What Makes Us Different?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF212121),
                ),
              ),
              const SizedBox(height: 28),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: services.map((srv) {
                  return Container(
                    width: 360,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(srv.icon, color: Colors.black, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                srv.title,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF212121),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                srv.desc,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 5. Frequently Asked Questions
  // ---------------------------------------------------------------------------
  Widget _buildFaqSection() {
    final faqs = [
      (
        q: 'How do I book a car on Twende?',
        a: 'Simply select your pick-up location, rental dates, and times on the search form, then click "SEARCH". Choose your vehicle, select any optional extras, and complete your reservation.',
      ),
      (
        q: 'What documents are required to pick up the vehicle?',
        a: 'You need a valid driver\'s license held for at least one year, a passport or government ID, and a credit card in the primary driver\'s name for the deposit.',
      ),
      (
        q: 'Can I cancel or modify my reservation?',
        a: 'Yes! Most bookings offer free cancellation up to 48 hours before pick-up. You can easily view and manage your bookings anytime under the Bookings tab.',
      ),
      (
        q: 'Is insurance included in the rental price?',
        a: 'Basic collision damage waiver and theft protection are included with most vehicles. Additional comprehensive insurance can be added during checkout.',
      ),
      (
        q: 'What is the fuel policy?',
        a: 'Our partners generally follow a "Like-for-like" policy: return the car with the exact same fuel level as when you picked it up.',
      ),
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Column(
            children: [
              const Text(
                'Frequently Asked Questions',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF212121),
                ),
              ),
              const SizedBox(height: 24),
              ...faqs.map((f) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: ExpansionTile(
                    title: Text(
                      f.q,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF212121),
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Text(
                          f.a,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 7. Customer Care Banner
  // ---------------------------------------------------------------------------
  Widget _buildCustomerCareSection(BuildContext context) {
    return Container(
      color: const Color(0xFF1E140E),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Column(
            children: [
              const Text(
                'Customer Care — Always Here to Help',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: () => context.push('/contact'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'CONTACT US',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 8. Footer
  // ---------------------------------------------------------------------------
  Widget _buildFooter(BuildContext context) {
    return Container(
      color: const Color(0xFF141414),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Column(
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => context.push('/about'),
                    child: const Text('About Us', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ),
                  TextButton(
                    onPressed: () => context.push('/contact'),
                    child: const Text('Contact', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ),
                  TextButton(
                    onPressed: () => context.push('/tos'),
                    child: const Text('Terms of Service', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Secure Payment Logos
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/stripe.png',
                    height: 24,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                  const SizedBox(width: 16),
                  Image.asset(
                    'assets/images/paypal.png',
                    height: 24,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                '© 2026 Twende Rental Service. All rights reserved.',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
