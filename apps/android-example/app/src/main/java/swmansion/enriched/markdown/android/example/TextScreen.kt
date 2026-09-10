package swmansion.enriched.markdown.android.example

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import com.swmansion.enriched.markdown.compose.EnrichedMarkdownText

@Composable
fun TextScreen(
  markdown: String,
  modifier: Modifier = Modifier,
) {
  var pendingLink by remember { mutableStateOf<PendingLink?>(null) }

  Column(
    modifier =
      modifier
        .fillMaxSize()
        .background(Color.White)
        .verticalScroll(rememberScrollState())
        .padding(horizontal = 16.dp, vertical = 16.dp),
  ) {
    EnrichedMarkdownText(
      markdown = markdown,
      modifier = Modifier.fillMaxWidth(),
      style = CustomMarkdownStyle,
      onLinkPress = { url -> pendingLink = PendingLink(url, isLongPress = false) },
      onLinkLongPress = { url -> pendingLink = PendingLink(url, isLongPress = true) },
    )
  }

  LinkPressDialog(pendingLink) { pendingLink = null }
}
