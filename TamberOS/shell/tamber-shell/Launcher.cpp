#include "Launcher.h"
#include <QSet>
#include <algorithm>
#undef signals
#include <gio/gdesktopappinfo.h>
Launcher::Launcher(QObject *parent):QObject(parent) { refresh(); }
void Launcher::refresh() {
 apps.clear(); QSet<QString> seen;
 GList *list=g_app_info_get_all();
 for(GList *it=list;it;it=it->next) {
  auto *app=G_APP_INFO(it->data); const char *raw=g_app_info_get_id(app);
  if(!raw || !g_app_info_should_show(app)) continue;
  QString id=QString::fromUtf8(raw); if(seen.contains(id)) continue; seen.insert(id);
  QString iconName;auto *icon=g_app_info_get_icon(app);
  if(icon && G_IS_THEMED_ICON(icon)){const auto names=g_themed_icon_get_names(G_THEMED_ICON(icon));if(names && names[0])iconName=QString::fromUtf8(names[0]);}
  const char *rawCategories = G_IS_DESKTOP_APP_INFO(app) ? g_desktop_app_info_get_categories(G_DESKTOP_APP_INFO(app)) : nullptr;
  const auto categories=QString::fromUtf8(rawCategories ? rawCategories : "");
  apps.append(QVariantMap{{"iconName",iconName},{"appId",id},{"name",QString::fromUtf8(g_app_info_get_display_name(app))},{"isGame",categories.contains("Game;",Qt::CaseInsensitive)}});
 }
 g_list_free_full(list,g_object_unref);
 std::sort(apps.begin(),apps.end(),[](const QVariant&a,const QVariant&b){return QString::localeAwareCompare(a.toMap()["name"].toString(),b.toMap()["name"].toString())<0;});
 emit applicationsChanged();
}
bool Launcher::launch(const QString &id) {
 bool known=false; for(const auto &a:apps) if(a.toMap()["appId"].toString()==id) known=true;
 if(!known){message="Application is no longer available";emit statusChanged();return false;}
 auto *app=g_desktop_app_info_new(id.toUtf8().constData()); GError *error=nullptr;
 // Delegate Desktop Entry field codes and argv parsing to GIO; never construct a shell command.
 auto *context=g_app_launch_context_new();
 // Panel roles belong to this process, not to applications it launches.
 g_app_launch_context_setenv(context,"QT_WAYLAND_SHELL_INTEGRATION","xdg-shell");
 bool ok=app && g_app_info_should_show(G_APP_INFO(app)) && g_app_info_launch(G_APP_INFO(app),nullptr,context,&error);
 message=ok ? "Launch requested" : error ? QString::fromUtf8(error->message) : "Application could not be launched";
 g_object_unref(context);
 if(error)g_error_free(error); if(app)g_object_unref(app);
 emit statusChanged(); if(ok)emit launchAccepted(id); return ok;
}
