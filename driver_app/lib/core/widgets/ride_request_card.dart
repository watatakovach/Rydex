import 'package:flutter/material.dart';

import '../../models/ride.dart';


class RideRequestCard
    extends StatelessWidget {

  final Ride ride;

  final bool isAccepting;

  final VoidCallback onAccept;

  final VoidCallback onDecline;


  const RideRequestCard({

    super.key,

    required this.ride,

    required this.isAccepting,

    required this.onAccept,

    required this.onDecline,

  });


  // ============================================================
  // FORMAT FARE
  // ============================================================

  String _formatFare() {

    if (ride.estimatedFare == null) {

      return 'Fare unavailable';

    }


    return 'KES ${ride.estimatedFare!.toStringAsFixed(0)}';

  }


  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {

    return Card(

      elevation: 4,

      child:
          Padding(

        padding:
            const EdgeInsets.all(
          16,
        ),


        child:
            Column(

          crossAxisAlignment:
              CrossAxisAlignment.start,


          children: [

            // ==================================================
            // HEADER
            // ==================================================

            Row(

              children: [

                Container(

                  padding:
                      const EdgeInsets.all(
                    10,
                  ),


                  decoration:
                      BoxDecoration(

                    color:
                        Colors.green
                            .withValues(
                      alpha: 0.1,
                    ),

                    shape:
                        BoxShape.circle,

                  ),


                  child:
                      const Icon(

                    Icons.local_taxi,

                    color:
                        Colors.green,

                  ),

                ),


                const SizedBox(
                  width: 12,
                ),


                const Expanded(

                  child:
                      Text(

                    'New Ride Request',

                    style:
                        TextStyle(

                      fontSize: 18,

                      fontWeight:
                          FontWeight.bold,

                    ),

                  ),

                ),


                // ==================================================
                // FARE
                // ==================================================

                Text(

                  _formatFare(),

                  style:
                      const TextStyle(

                    fontSize: 16,

                    fontWeight:
                        FontWeight.bold,

                  ),

                ),

              ],

            ),


            const SizedBox(
              height: 20,
            ),


            // ==================================================
            // PICKUP
            // ==================================================

            Row(

              crossAxisAlignment:
                  CrossAxisAlignment.start,


              children: [

                const Icon(

                  Icons.my_location,

                  size: 22,

                  color:
                      Colors.green,

                ),


                const SizedBox(
                  width: 12,
                ),


                Expanded(

                  child:
                      Column(

                    crossAxisAlignment:
                        CrossAxisAlignment.start,


                    children: [

                      const Text(

                        'Pickup',

                        style:
                            TextStyle(

                          fontSize: 12,

                          fontWeight:
                              FontWeight.bold,

                          color:
                              Colors.grey,

                        ),

                      ),


                      const SizedBox(
                        height: 4,
                      ),


                      Text(

                        '${ride.pickupLatitude}, ${ride.pickupLongitude}',

                        style:
                            const TextStyle(

                          fontSize: 15,

                        ),

                      ),

                    ],

                  ),

                ),

              ],

            ),


            // ==================================================
            // ROUTE LINE
            // ==================================================

            Padding(

              padding:
                  const EdgeInsets.only(
                left: 10,
              ),


              child:
                  Container(

                height: 24,

                width: 2,

                color:
                    Colors.grey[300],

              ),

            ),


            // ==================================================
            // DESTINATION
            // ==================================================

            Row(

              crossAxisAlignment:
                  CrossAxisAlignment.start,


              children: [

                const Icon(

                  Icons.location_on,

                  size: 22,

                  color:
                      Colors.red,

                ),


                const SizedBox(
                  width: 12,
                ),


                Expanded(

                  child:
                      Column(

                    crossAxisAlignment:
                        CrossAxisAlignment.start,


                    children: [

                      const Text(

                        'Destination',

                        style:
                            TextStyle(

                          fontSize: 12,

                          fontWeight:
                              FontWeight.bold,

                          color:
                              Colors.grey,

                        ),

                      ),


                      const SizedBox(
                        height: 4,
                      ),


                      Text(

                        '${ride.destinationLatitude}, ${ride.destinationLongitude}',

                        style:
                            const TextStyle(

                          fontSize: 15,

                        ),

                      ),

                    ],

                  ),

                ),

              ],

            ),


            const SizedBox(
              height: 20,
            ),


            // ==================================================
            // RIDE ID
            // ==================================================

            Text(

              'Ride #${ride.id}',

              style:
                  TextStyle(

                fontSize: 12,

                color:
                    Colors.grey[600],

              ),

            ),


            const SizedBox(
              height: 16,
            ),


            // ==================================================
            // ACTION BUTTONS
            // ==================================================

            Row(

              children: [

                // ==============================================
                // DECLINE
                // ==============================================

                Expanded(

                  child:
                      OutlinedButton(

                    onPressed:
                        isAccepting
                            ? null
                            : onDecline,


                    child:
                        const Text(
                      'DECLINE',
                    ),

                  ),

                ),


                const SizedBox(
                  width: 12,
                ),


                // ==============================================
                // ACCEPT
                // ==============================================

                Expanded(

                  child:
                      ElevatedButton(

                    onPressed:
                        isAccepting
                            ? null
                            : onAccept,


                    child:

                        isAccepting

                            ? const SizedBox(

                                height: 20,

                                width: 20,

                                child:
                                    CircularProgressIndicator(

                                  strokeWidth:
                                      2,

                                ),

                              )

                            : const Text(
                                'ACCEPT RIDE',
                              ),

                  ),

                ),

              ],

            ),

          ],

        ),

      ),

    );

  }

}