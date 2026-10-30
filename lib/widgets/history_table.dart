import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'glass_card.dart';

class HistoryTableColumn {
  final String title;
  final double? width;
  final Alignment alignment;

  const HistoryTableColumn({
    required this.title,
    this.width,
    this.alignment = Alignment.centerLeft,
  });
}

class HistoryTableCell {
  final String text;
  final bool isChip;
  final Color? chipColor;

  const HistoryTableCell({
    required this.text,
    this.isChip = false,
    this.chipColor,
  });
}

class HistoryTableRow {
  final List<HistoryTableCell> cells;

  const HistoryTableRow({required this.cells});
}

/// Komponen tabel riwayat serbaguna bergaya kaca (Glassmorphism)
/// Mendukung pagination (10 baris per halaman), tombol Segarkan, tombol Salin/Unduh CSV,
/// baris selang-seling semi-transparan, status chip berwarna, dan responsive view di mobile.
class HistoryTable extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<HistoryTableColumn> columns;
  final List<HistoryTableRow> rows;
  final VoidCallback onRefresh;
  final bool isLoading;
  final String csvContent;

  const HistoryTable({
    super.key,
    required this.title,
    required this.subtitle,
    required this.columns,
    required this.rows,
    required this.onRefresh,
    this.isLoading = false,
    required this.csvContent,
  });

  @override
  State<HistoryTable> createState() => _HistoryTableState();
}

class _HistoryTableState extends State<HistoryTable> {
  static const int _pageSize = 10;
  int _currentPage = 1;

  @override
  void didUpdateWidget(covariant HistoryTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.rows.length != oldWidget.rows.length) {
      final maxPage = (widget.rows.length / _pageSize).ceil();
      if (_currentPage > maxPage && maxPage > 0) {
        _currentPage = maxPage;
      }
    }
  }

  void _handleDownloadCsv() {
    Clipboard.setData(ClipboardData(text: widget.csvContent));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Color(0xFF34D399), size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Data CSV berhasil disalin ke clipboard! Siap di-paste ke Excel / Notepad.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E2638),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int totalRows = widget.rows.length;
    final int totalPages = totalRows == 0 ? 1 : (totalRows / _pageSize).ceil();
    final int safePage = _currentPage.clamp(1, totalPages);

    final int startIndex = (safePage - 1) * _pageSize;
    final int endIndex = (startIndex + _pageSize).clamp(0, totalRows);
    final List<HistoryTableRow> currentRows = totalRows == 0 ? [] : widget.rows.sublist(startIndex, endIndex);

    final bool isMobile = MediaQuery.of(context).size.width < 700;

    return GlassCard(
      padding: const EdgeInsets.all(18),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Toolbar Atas: Judul, Tombol Segarkan, & Tombol Unduh CSV
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tombol Segarkan
                  IconButton(
                    onPressed: widget.isLoading ? null : widget.onRefresh,
                    icon: widget.isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.refresh_rounded, size: 20, color: Colors.white70),
                    tooltip: 'Segarkan Data',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),

                  // Tombol Unduh / Salin CSV
                  ElevatedButton.icon(
                    onPressed: _handleDownloadCsv,
                    icon: const Icon(Icons.file_download_outlined, size: 15),
                    label: Text(
                      isMobile ? 'CSV' : 'Unduh CSV',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.12),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Tampilan Konten: Kosong, Mobile Cards, atau Desktop Table
          if (widget.isLoading && totalRows == 0)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
              ),
            )
          else if (totalRows == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.inbox_outlined, size: 40, color: Colors.white.withOpacity(0.35)),
                    const SizedBox(height: 8),
                    Text(
                      'Belum ada riwayat',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (isMobile)
            // Mobile: Tampilan Daftar Kartu Responsif
            _buildMobileCards(currentRows)
          else
            // Desktop: Tampilan Tabel Standar dengan Header Tebal & Baris Selang-Seling
            _buildDesktopTable(currentRows),

          const SizedBox(height: 14),

          // Pagination Footer: "Halaman X dari N" + Tombol Sebelumnya / Berikutnya
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Menampilkan ${totalRows == 0 ? 0 : startIndex + 1}-${endIndex} dari $totalRows data',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.55),
                ),
              ),

              Row(
                children: [
                  Text(
                    'Halaman $safePage dari $totalPages',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Tombol Sebelumnya
                  IconButton(
                    onPressed: safePage > 1
                        ? () {
                            setState(() {
                              _currentPage--;
                            });
                          }
                        : null,
                    icon: const Icon(Icons.chevron_left_rounded, size: 20),
                    color: Colors.white,
                    disabledColor: Colors.white24,
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                  ),

                  // Tombol Berikutnya
                  IconButton(
                    onPressed: safePage < totalPages
                        ? () {
                            setState(() {
                              _currentPage++;
                            });
                          }
                        : null,
                    icon: const Icon(Icons.chevron_right_rounded, size: 20),
                    color: Colors.white,
                    disabledColor: Colors.white24,
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTable(List<HistoryTableRow> rows) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header Tabel Tebal
          Container(
            color: Colors.white.withOpacity(0.08),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: widget.columns.map((col) {
                return Expanded(
                  child: Align(
                    alignment: col.alignment,
                    child: Text(
                      col.title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Baris Selang-Seling Semi-Transparan
          ...rows.asMap().entries.map((entry) {
            final int index = entry.key;
            final HistoryTableRow row = entry.value;
            final bool isAlternate = index % 2 == 1;

            return Container(
              color: isAlternate ? Colors.white.withOpacity(0.03) : Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.white.withOpacity(0.06), width: 1),
                ),
              ),
              child: Row(
                children: row.cells.asMap().entries.map((cellEntry) {
                  final int colIndex = cellEntry.key;
                  final HistoryTableCell cell = cellEntry.value;
                  final colAlignment = colIndex < widget.columns.length
                      ? widget.columns[colIndex].alignment
                      : Alignment.centerLeft;

                  return Expanded(
                    child: Align(
                      alignment: colAlignment,
                      child: _renderCell(cell),
                    ),
                  );
                }).toList(),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMobileCards(List<HistoryTableRow> rows) {
    return Column(
      children: rows.map((row) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.18),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            children: row.cells.asMap().entries.map((entry) {
              final int idx = entry.key;
              final cell = entry.value;
              final colTitle = idx < widget.columns.length ? widget.columns[idx].title : '';

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      colTitle,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.55),
                      ),
                    ),
                    _renderCell(cell, isMobile: true),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  Widget _renderCell(HistoryTableCell cell, {bool isMobile = false}) {
    if (!cell.isChip) {
      return Text(
        cell.text,
        style: TextStyle(
          fontSize: isMobile ? 12 : 12,
          fontWeight: FontWeight.w500,
          color: Colors.white.withOpacity(0.9),
        ),
      );
    }

    final Color color = cell.chipColor ?? const Color(0xFF10B981);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Text(
        cell.text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
