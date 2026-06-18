package com.cooler.app

object Config {
    const val GITHUB_OWNER = "YOUR_USERNAME"
    const val GITHUB_REPO = "cooler"

    val UPDATE_JSON_URL get() = "https://raw.githubusercontent.com/$GITHUB_OWNER/$GITHUB_REPO/main/latest.json"
    fun apkUrl(versionName: String) = "https://github.com/$GITHUB_OWNER/$GITHUB_REPO/releases/download/v$versionName/app-release.apk"
}
