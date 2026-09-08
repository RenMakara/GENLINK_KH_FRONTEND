package kh.edu.acleda.genlink.genlink_frontend

import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private companion object {
        const val CHANNEL = "kh.edu.acleda.genlink/local_network"
        const val ENSURE_PERMISSION = "ensurePermission"
        const val REQUEST_CODE = 3717
        const val ACCESS_LOCAL_NETWORK = "android.permission.ACCESS_LOCAL_NETWORK"
    }

    private var pendingPermissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == ENSURE_PERMISSION) {
                    ensureLocalNetworkPermission(result)
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun ensureLocalNetworkPermission(result: MethodChannel.Result) {
        // The permission is declared in the debug manifest because production
        // uses the public HTTPS API and must not show a local-network prompt.
        val isDebuggable =
            (applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0
        if (Build.VERSION.SDK_INT < 37 || !isDebuggable) {
            result.success(true)
            return
        }

        if (checkSelfPermission(ACCESS_LOCAL_NETWORK) == PackageManager.PERMISSION_GRANTED) {
            result.success(true)
            return
        }

        if (pendingPermissionResult != null) {
            result.error("REQUEST_IN_PROGRESS", "Local network permission request is already in progress", null)
            return
        }

        pendingPermissionResult = result
        requestPermissions(arrayOf(ACCESS_LOCAL_NETWORK), REQUEST_CODE)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)

        if (requestCode != REQUEST_CODE) return

        val result = pendingPermissionResult ?: return
        pendingPermissionResult = null
        result.success(grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED)
    }
}
