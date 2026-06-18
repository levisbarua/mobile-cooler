package com.cooler.app

object Config {
    const val GITHUB_OWNER = "levisbarua"
    const val GITHUB_REPO = "cooler"

    val GITHUB_API_LATEST_RELEASE get() = "https://api.github.com/repos/$GITHUB_OWNER/$GITHUB_REPO/releases/latest"
}
