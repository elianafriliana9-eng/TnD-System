import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PDFLetterhead {
  // Company Info - UPDATE THESE VALUES
  static const String companyName = 'Training & Development Department';
  static const String companyAddress = 'Tangerang, Banten';
  static const String companyEmail = 'Email: info@tndsystem.co.id';
  static const String companyWebsite = 'www.tndsystem.co.id';
  
  // Report Info
  static const String reportTitle = 'LAPORAN REKOMENDASI PERBAIKAN';
  static const String reportSubtitle = 'Hasil Visit';
  
  /// Build company letterhead with professional layout
  static pw.Widget buildLetterhead({
    pw.ImageProvider? logo,
  }) {
    return pw.Column(
      children: [
        // Top border line
        pw.Container(
          height: 4,
          decoration: pw.BoxDecoration(
            gradient: pw.LinearGradient(
              colors: [
                PdfColors.blue900,
                PdfColors.blue700,
                PdfColors.blue500,
              ],
            ),
          ),
        ),
        
        pw.SizedBox(height: 15),
        
        // Header content - CENTER ALIGNED
        pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            // Logo section
            if (logo != null) ...[
              pw.Container(
                width: 80,
                height: 80,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.blue200, width: 2),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                padding: const pw.EdgeInsets.all(8),
                child: pw.Image(logo),
              ),
              pw.SizedBox(height: 12),
            ],
            
            // Company info - centered
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  companyName,
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                    letterSpacing: 0.5,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  companyAddress,
                  style: pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey800,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  companyEmail,
                  style: pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey700,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  companyWebsite,
                  style: pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.blue700,
                    fontStyle: pw.FontStyle.italic,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            ),
          ],
        ),
        
        pw.SizedBox(height: 12),
        
        // Bottom border line
        pw.Container(
          height: 2,
          decoration: pw.BoxDecoration(
            gradient: pw.LinearGradient(
              colors: [
                PdfColors.blue900,
                PdfColors.blue300,
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  /// Build report title section with document info
  static pw.Widget buildReportTitle({
    required String documentNumber,
    required String documentDate,
  }) {
    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 20),
      child: pw.Column(
        children: [
          // Main title
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue900,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Column(
              children: [
                pw.Text(
                  reportTitle,
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                    letterSpacing: 1,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  reportSubtitle,
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.blue50,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          
          pw.SizedBox(height: 15),
          
          // Document metadata
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Row(
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.blue,
                        borderRadius: pw.BorderRadius.circular(3),
                      ),
                      child: pw.Text(
                        'No. Dokumen',
                        style: pw.TextStyle(
                          fontSize: 8,
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Text(
                      documentNumber,
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                  ],
                ),
                pw.Row(
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.blue,
                        borderRadius: pw.BorderRadius.circular(3),
                      ),
                      child: pw.Text(
                        'Tanggal',
                        style: pw.TextStyle(
                          fontSize: 8,
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Text(
                      documentDate,
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build section title with professional styling
  static pw.Widget buildSectionTitle(String title, {PdfColor? color}) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 20, bottom: 12),
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: [
            color ?? PdfColors.blue900,
            (color ?? PdfColors.blue900).shade(0.7),
          ],
        ),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            width: 4,
            height: 16,
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(2),
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build info row with professional layout
  static pw.Widget buildInfoRow(String label, String value) {
    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 4),
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        border: pw.Border(
          left: pw.BorderSide(color: PdfColors.blue, width: 3),
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 130,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey800,
              ),
            ),
          ),
          pw.Text(
            ': ',
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey600,
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build professional footer
  static pw.Widget buildFooter(int pageNumber, int totalPages) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 20),
      padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 15),
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: [
            PdfColors.grey200,
            PdfColors.grey100,
          ],
        ),
        border: pw.Border(
          top: pw.BorderSide(
            color: PdfColors.blue900,
            width: 2,
          ),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Dokumen ini dibuat secara elektronis dan sah tanpa tanda tangan basah',
                style: pw.TextStyle(
                  fontSize: 7,
                  color: PdfColors.grey700,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                '© ${DateTime.now().year} $companyName - Confidential',
                style: pw.TextStyle(
                  fontSize: 6,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue900,
              borderRadius: pw.BorderRadius.circular(3),
            ),
            child: pw.Text(
              'Hal. $pageNumber / $totalPages',
              style: pw.TextStyle(
                fontSize: 8,
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build professional signature section
  static pw.Widget buildSignatureSection({
    required String auditorName,
    required String signatureDate,
    pw.ImageProvider? signatureImage,
  }) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 30, bottom: 20),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Container(
            width: 200,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // Label
                pw.Text(
                  'Visitor,',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey800,
                  ),
                ),
                pw.SizedBox(height: 5),
                
                // Signature Image (no border/container)
                if (signatureImage != null)
                  pw.Container(
                    height: 60,
                    width: 150,
                    child: pw.Image(signatureImage, fit: pw.BoxFit.contain),
                  )
                else
                  pw.SizedBox(height: 60),
                
                pw.SizedBox(height: 5),
                
                // Line above name
                pw.Container(
                  width: 150,
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(
                        color: PdfColors.black,
                        width: 1,
                      ),
                    ),
                  ),
                  child: pw.Text(
                    auditorName,
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.black,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                
                pw.SizedBox(height: 4),
                
                // Date below
                pw.Text(
                  signatureDate,
                  style: pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey700,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build dual signature section (Visitor & PIC)
  static pw.Widget buildDualSignatureSection({
    required String visitorName,
    required String picName,
    required String signatureDate,
    pw.ImageProvider? visitorSignature,
    pw.ImageProvider? picSignature,
  }) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 30, bottom: 20),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          // Visitor Signature (Left)
          pw.Container(
            width: 200,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // Label
                pw.Text(
                  'Visitor,',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey800,
                  ),
                ),
                pw.SizedBox(height: 5),
                
                // Signature Image
                if (visitorSignature != null)
                  pw.Container(
                    height: 60,
                    width: 150,
                    child: pw.Image(visitorSignature, fit: pw.BoxFit.contain),
                  )
                else
                  pw.SizedBox(height: 60),
                
                pw.SizedBox(height: 5),
                
                // Line above name
                pw.Container(
                  width: 150,
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(
                        color: PdfColors.black,
                        width: 1,
                      ),
                    ),
                  ),
                  child: pw.Text(
                    visitorName,
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.black,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                
                pw.SizedBox(height: 4),
                
                // Date below
                pw.Text(
                  signatureDate,
                  style: pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey700,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            ),
          ),
          
          // PIC Signature (Right)
          pw.Container(
            width: 200,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // Label
                pw.Text(
                  'Person in Charge (PIC),',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey800,
                  ),
                ),
                pw.SizedBox(height: 5),
                
                // Signature Image
                if (picSignature != null)
                  pw.Container(
                    height: 60,
                    width: 150,
                    child: pw.Image(picSignature, fit: pw.BoxFit.contain),
                  )
                else
                  pw.SizedBox(height: 60),
                
                pw.SizedBox(height: 5),
                
                // Line above name
                pw.Container(
                  width: 150,
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(
                        color: PdfColors.black,
                        width: 1,
                      ),
                    ),
                  ),
                  child: pw.Text(
                    picName,
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.black,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                
                pw.SizedBox(height: 4),
                
                // Date below
                pw.Text(
                  signatureDate,
                  style: pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey700,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
