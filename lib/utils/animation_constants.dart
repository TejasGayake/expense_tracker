import 'package:flutter/material.dart';

// Durations
const Duration kFastDuration = Duration(milliseconds: 150);
const Duration kNormalDuration = Duration(milliseconds: 250);
const Duration kSlowDuration = Duration(milliseconds: 400);
const Duration kEntranceDuration = Duration(milliseconds: 300);

// Curves
const Curve kDefaultCurve = Curves.easeOutCubic;
const Curve kEntranceCurve = Curves.easeOutQuart;
const Curve kBounceCurve = Curves.elasticOut;

// Stagger delays
const Duration kStaggerDelay = Duration(milliseconds: 50);
const Duration kCardStaggerDelay = Duration(milliseconds: 80);
