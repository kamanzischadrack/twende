// lib/widgets/car_card.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/env_config.dart';
import '../core/theme/app_colors.dart';
import '../models/car.dart';
import 'bc_button.dart';

class CarCard extends StatelessWidget {
  final Car car;
  final DateTime? from;
  final DateTime? to;
  final String? pickupLocation;
  final String? dropOffLocation;
  final String? pickupLocationName;
  final bool hidePrice;

  const CarCard({
    super.key,
    required this.car,
    this.from,
    this.to,
    this.pickupLocation,
    this.dropOffLocation,
    this.pickupLocationName,
    this.hidePrice = false,
  });

  Widget _buildExtraItem({
    required int value,
    required String label,
  }) {
    if (value <= -1) return const SizedBox.shrink();

    IconData icon;

    if (value == 0) {
      icon = Icons.check;
    } else if (value == -1) {
      icon = Icons.close;
    } else {
      icon = Icons.info_outline;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.black),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF333333),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecBadge({
    required Widget icon,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      margin: const EdgeInsets.only(right: 6),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFDDDDDD), width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF333333),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int days = 1;
    if (from != null && to != null) {
      final diff = to!.difference(from!).inHours;
      days = (diff / 24).ceil();
      if (days < 1) days = 1;
    }

    final pricePerDay = car.price;
    final totalPrice = pricePerDay * days;
    const currencySymbol = '\$';

    return Container(
      constraints: const BoxConstraints(maxWidth: 480),
      margin: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Car Name
          Text(
            car.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 12),

          // 2. Car Image
          SizedBox(
            height: 140,
            child: car.image != null && car.image!.isNotEmpty
                ? (car.image!.startsWith('assets/')
                    ? Image.asset(
                        car.image!,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.directions_car,
                          size: 80,
                          color: Colors.black,
                        ),
                      )
                    : Image.network(
                        car.image!.startsWith('http')
                            ? car.image!
                            : '${EnvConfig.cdnCars}/${car.image}',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Image.asset(
                          'assets/images/midi.png',
                          fit: BoxFit.contain,
                        ),
                      ))
                : Image.asset(
                    'assets/images/midi.png',
                    fit: BoxFit.contain,
                  ),
          ),
          const SizedBox(height: 12),

          // 3. Specs Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Fuel type
                _buildSpecBadge(
                  icon: const Icon(Icons.local_gas_station, size: 16, color: Colors.black),
                  text: car.type.toUpperCase(),
                ),
                // Gearbox
                _buildSpecBadge(
                  icon: const Icon(Icons.account_tree, size: 16, color: Colors.black),
                  text: car.gearbox.toUpperCase(),
                ),
                // Seats
                if (car.seats > 0)
                  _buildSpecBadge(
                    icon: const Icon(Icons.person, size: 16, color: Colors.black),
                    text: '${car.seats}',
                  ),
                // Doors
                if (car.doors > 0)
                  _buildSpecBadge(
                    icon: Image.asset(
                      'assets/images/car-door.png',
                      width: 14,
                      height: 14,
                      errorBuilder: (_, __, ___) => const Icon(Icons.meeting_room, size: 14),
                    ),
                    text: '${car.doors}',
                  ),
                // Aircon
                if (car.aircon)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFDDDDDD), width: 1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.ac_unit, size: 16, color: Colors.black),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 4. Mileage line
          Row(
            children: [
              const Icon(Icons.directions_car, size: 18, color: Colors.black),
              const SizedBox(width: 8),
              Text(
                'Mileage: ${car.mileage == -1 ? 'Unlimited' : '${car.mileage} km'}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF333333)),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // 5. Fuel policy line
          Row(
            children: [
              const Icon(Icons.local_gas_station, size: 18, color: Colors.black),
              const SizedBox(width: 8),
              Text(
                'Fuel policy: ${car.fuelPolicy}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF333333)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 6. Extras list
          _buildExtraItem(
            value: car.cancellation,
            label: car.cancellation == 0 ? 'Free Cancellation' : 'Paid Cancellation',
          ),
          _buildExtraItem(
            value: car.amendments,
            label: car.amendments == 0 ? 'Free Amendments' : 'Paid Amendments',
          ),
          _buildExtraItem(
            value: car.theftProtection,
            label: 'Theft Protection',
          ),
          _buildExtraItem(
            value: car.collisionDamageWaiver,
            label: 'Collision Damage Waiver',
          ),
          _buildExtraItem(
            value: car.fullInsurance,
            label: 'Full Insurance',
          ),
          _buildExtraItem(
            value: car.additionalDriver,
            label: 'Additional Driver',
          ),
          if (car.deposit > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 20, color: Colors.black),
                  const SizedBox(width: 8),
                  Text(
                    'Deposit: $currencySymbol${car.deposit.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Color(0xFF333333),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

          const Divider(height: 20, color: Color(0xFFEBEBEB)),

          // 7. Footer: Supplier info + Pricing
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Supplier details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (car.supplier.avatar != null && car.supplier.avatar!.isNotEmpty)
                          Container(
                            width: 56,
                            height: 28,
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(3),
                              border: Border.all(color: const Color(0xFFE6E6E6), width: 1),
                            ),
                            child: car.supplier.avatar!.startsWith('assets/')
                                ? Image.asset(
                                    car.supplier.avatar!,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.business, size: 20),
                                  )
                                : Image.network(
                                    car.supplier.avatar!.startsWith('http')
                                        ? car.supplier.avatar!
                                        : '${EnvConfig.cdnUsers}/${car.supplier.avatar}',
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.business, size: 20),
                                  ),
                          )
                        else
                          const Icon(Icons.business, size: 24, color: Colors.black),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            car.supplier.fullName ?? '',
                            style: const TextStyle(
                              color: Color(0xFFA1A1A1),
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (car.rating != null && car.rating! >= 1) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            car.rating!.toStringAsFixed(1),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Image.asset(
                            'assets/images/rating-icon.png',
                            width: 14,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.star,
                              size: 14,
                              color: Colors.black,
                            ),
                          ),
                          if (car.trips >= 10) ...[
                            const SizedBox(width: 4),
                            Text(
                              '(${car.trips} trips)',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFFA2A2A2),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Price
              if (!hidePrice)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$days ${days == 1 ? 'day' : 'days'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFA1A1A1),
                      ),
                    ),
                    Text(
                      '$currencySymbol${totalPrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF383838),
                        height: 1.2,
                      ),
                    ),
                    Text(
                      'Price per day $currencySymbol${pricePerDay.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFA1A1A1),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // 8. Book Button
          if (!hidePrice &&
              pickupLocation != null &&
              dropOffLocation != null &&
              from != null &&
              to != null) ...[
            const SizedBox(height: 14),
            BcButton(
              label: 'BOOK',
              onPress: () {
                final params = {
                  'car': car.id,
                  'pickupLocation': pickupLocation!,
                  'dropOffLocation': dropOffLocation!,
                  'from': from!.millisecondsSinceEpoch.toString(),
                  'to': to!.millisecondsSinceEpoch.toString(),
                };
                final uri = Uri(path: '/checkout', queryParameters: params);
                context.push(uri.toString());
              },
            ),
          ],
        ],
      ),
    );
  }
}
