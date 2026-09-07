package swmansion.enriched.markdown.android.example

import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.layout.Column
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.platform.LocalContext

/** A link the user activated, held until they confirm opening it or dismiss the dialog. */
data class PendingLink(
  val url: String,
  val isLongPress: Boolean,
)

/**
 * Confirms a link activation before anything leaves the app.
 *
 * The example app deliberately does not open a browser straight from a link callback: the dialog
 * names which callback fired — tap or long press — and on which URL, so link handling stays visible
 * even when no browser is installed or the intent fails.
 */
@Composable
fun LinkPressDialog(
  pending: PendingLink?,
  onDismiss: () -> Unit,
) {
  if (pending == null) return
  val context = LocalContext.current

  AlertDialog(
    onDismissRequest = onDismiss,
    title = { Text(if (pending.isLongPress) "Link long pressed" else "Link pressed") },
    text = {
      Column {
        Text(pending.url)
        Text("Open this link in the browser?")
      }
    },
    confirmButton = {
      TextButton(
        onClick = {
          runCatching {
            context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(pending.url)))
          }
          onDismiss()
        },
      ) {
        Text("Open")
      }
    },
    dismissButton = {
      TextButton(onClick = onDismiss) { Text("Cancel") }
    },
  )
}
