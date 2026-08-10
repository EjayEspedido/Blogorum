import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

class PostCarouselLarge extends StatefulWidget {
  final List<String> images;

  const PostCarouselLarge({super.key, required this.images});

  @override
  State<PostCarouselLarge> createState() => _PostCarouselLargeState();
}

class _PostCarouselLargeState extends State<PostCarouselLarge> {
  final CarouselSliderController _controller = CarouselSliderController();
  int _current = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        CarouselSlider(
          carouselController: _controller,
          options: CarouselOptions(
            height: 400,
            viewportFraction: 1,
            enlargeCenterPage: false,
            enableInfiniteScroll: widget.images.length > 1,
            autoPlay: false,
            onPageChanged: (index, reason) {
              setState(() {
                _current = index;
              });
            },
          ),
          items: widget.images.map((url) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                color: Colors.black12,
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
            );
          }).toList(),
        ),

        // Left Arrow
        if (widget.images.length > 1)
          Positioned(
            left: 8,
            top: 0,
            bottom: 0,
            child: Center(
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.black45,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.chevron_left, color: Colors.white),
                  onPressed: _controller.previousPage,
                ),
              ),
            ),
          ),

        // Right Arrow
        if (widget.images.length > 1)
          Positioned(
            right: 8,
            top: 0,
            bottom: 0,
            child: Center(
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.black45,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.chevron_right, color: Colors.white),
                  onPressed: _controller.nextPage,
                ),
              ),
            ),
          ),

        

        // Image Counter
        if (widget.images.length > 1)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_current + 1}/${widget.images.length}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.white),
              ),
            ),
          ),

        // Dots
        if (widget.images.length > 1)
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.images.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _current == index ? 10 : 6,
                  height: _current == index ? 10 : 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _current == index ? Colors.white : Colors.white54,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
