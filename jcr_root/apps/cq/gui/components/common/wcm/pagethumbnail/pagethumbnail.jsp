<%--
  ADOBE CONFIDENTIAL

  Copyright 2013 Adobe Systems Incorporated
  All Rights Reserved.

  NOTICE:  All information contained herein is, and remains
  the property of Adobe Systems Incorporated and its suppliers,
  if any.  The intellectual and technical concepts contained
  herein are proprietary to Adobe Systems Incorporated and its
  suppliers and may be covered by U.S. and Foreign Patents,
  patents in process, and are protected by trade secret or copyright law.
  Dissemination of this information or reproduction of this material
  is strictly forbidden unless prior written permission is obtained
  from Adobe Systems Incorporated.
--%><%
%><%@include file="/libs/granite/ui/global.jsp" %><%
%><%@page session="false"
          import="java.util.Calendar,
                  org.apache.jackrabbit.util.Text,
                  com.adobe.cq.launches.api.Launch,
                  com.day.cq.wcm.api.Template,
                  com.adobe.cq.wcm.launches.utils.LaunchUtils,
                  com.adobe.granite.ui.components.AttrBuilder,
                  com.adobe.granite.ui.components.ComponentHelper.Options,
                  com.adobe.granite.ui.components.Config,
                  com.adobe.granite.ui.components.Tag,
                  com.day.cq.wcm.api.Page,
                  com.day.cq.wcm.api.NameConstants,
                  com.adobe.granite.ui.components.ValueMapResourceWrapper,
                  org.apache.sling.api.resource.*" %><%

    Config cfg = cmp.getConfig();

    Page targetPage = null;

    Resource targetResource = resourceResolver.getResource(cmp.getExpressionHelper().getString(cfg.get("page", String.class)));
    if(targetResource == null) {
        return;
    }

    boolean isPage = false;
    boolean isTemplate = (targetResource.adaptTo(Template.class) != null);

    if(!isTemplate) {
        targetPage = findPage(targetResource);
        if(targetPage == null) {
            return;
        } else {
            isPage = true;
        }
    }

    Tag tag = cmp.consumeTag();
    AttrBuilder attrs = tag.getAttrs();
    attrs.addClass("cq-wcm-pagethumbnail");
    attrs.addClass(cfg.get("class", String.class));

    String pageDialogThumbnailPreview = "/libs/cq/gui/content/siteadmin/admin/pagepreview";
    String templateDialogThumbnailPreview = "/libs/cq/gui/content/siteadmin/admin/pagepreview";

    String path = targetResource.getPath();

    attrs.add("data-cq-wcm-pagethumbnail-path", path);
    attrs.add("data-is-template", isTemplate);

    AttrBuilder thumbnailAttr = new AttrBuilder(request, xssAPI);
    thumbnailAttr.addClass("foundation-layout-thumbnail");

    if (cfg.get("quiet", false)) {
        thumbnailAttr.addClass("foundation-layout-thumbnail-quiet");
    }

    String thumbnailLabel = isPage ? "Page thumbnail" : "Template thumbnail";
    String thumbnailUrl = isPage ? getPageThumbnailUrl(targetPage, resourceResolver) : getTemplateThumbnailUrl(targetResource, resourceResolver);

%><div <%= attrs.build() %>>
    <div <%= thumbnailAttr.build() %>>
        <div class="foundation-layout-thumbnail-image grid">
            <article class="card-page">
                <a>
                    <span class="image"><img class="cq-wcm-pagethumbnail-image" src="<%= request.getContextPath() + thumbnailUrl %>" alt="<%= i18n.get(thumbnailLabel) %>"></span>
                </a>
            </article>
        </div>
    </div>
    <div class="foundation-field-editable foundation-layout-util-vmargin">
        <div class="foundation-field-edit"><%
            Resource preview = resource.getChild("preview");
            Resource wrapper = new ValueMapResourceWrapper(preview, "cq/gui/components/siteadmin/admin/pagepreview");
            ValueMap vm = wrapper.adaptTo(ValueMap.class);
            vm.put("basePath", vm.get("basePath", isPage ? pageDialogThumbnailPreview : templateDialogThumbnailPreview));

            if (preview != null) { %>
                <button is="coral-button" class="cq-wcm-pagethumbnail-activator" type="button" autocomplete="off"><%= i18n.get("Generate Preview") %></button>
                <sling:include resource="<%= preview %>" /><%
            }
            Resource edit = resource.getChild("edit");
            if (edit != null) {
                cmp.include(edit, new Options().rootField(false));
            }

			// Removes the upload file button
			// Resource upload = resource.getChild("upload");
            // if (upload != null) {
            //     cmp.include(upload, new Options().rootField(false));
            // }

            Resource assetpicker = resource.getChild("assetpicker");
            if (assetpicker != null) {
                cmp.include(assetpicker, new Options().rootField(false));
            }

			if (/*upload != null ||*/ assetpicker != null) {
                %><button is="coral-button" type="reset" hidden><%= i18n.get("Revert") %></button><%
            } %>
        </div>
    </div>
</div><%!

    private Page findPage(Resource r) {
        if (r == null) {
            return null;
        }

        Page p = r.adaptTo(Page.class);

        if (p != null) {
            return p;
        }

        return findPage(r.getParent());
    }

    private String getPageThumbnailUrl(Page page, ResourceResolver resourceResolver) {
        String pagePath = page.getPath();

        String url = Text.escapePath(pagePath) + ".thumb.319.319.png";

        Resource contentResource = page.getContentResource("image/file/jcr:content");
        if (contentResource == null) {
            if (LaunchUtils.isLaunchBasedPath(page.getPath())) {
                Resource launchRes = LaunchUtils.getLaunchResource(page.getContentResource());
                Launch launch = launchRes.adaptTo(Launch.class);
                if (launch != null) {
                    String launchRootResPath = launch.getSourceRootResource().getPath();
                    url = Text.escapePath(launchRootResPath) + ".thumb.319.319.png";
                    return url;
                }
            }
        }

        ValueMap pageProps = page.getProperties();
        Calendar pageLastMod = pageProps.get("cq:lastModified", Calendar.class);
        ValueMap imageProps = page.getProperties("image/file/jcr:content");
        Calendar imageLastMod = imageProps.get("jcr:lastModified", pageLastMod);
        Calendar lastMod;
        if (pageLastMod != null && pageLastMod.after(imageLastMod)) {
            lastMod = pageLastMod;
        } else {
            lastMod = imageLastMod;
        }
        if (lastMod != null) {
            url += "?ck=" + (lastMod.getTimeInMillis() / 1000);
        }

        return url;
    }

    private String getTemplateThumbnailUrl(Resource resource, ResourceResolver resourceResolver) {
        Template template = resource.adaptTo(Template.class);

        String thumbnailPath = template.getThumbnailPath();
        if (thumbnailPath == null) {
            thumbnailPath = "/libs/cq/ui/widgets/themes/default/icons/240x180/page.png.thumb.319.319.png";
        }
        String thumbnailUrl = Text.escapePath(thumbnailPath);

        // check for last modified date
        Resource thumbnailResource = resource.getResourceResolver().getResource(template.getPath() + "/"
                + NameConstants.NN_THUMBNAIL_PNG + "/jcr:content");
        if (thumbnailResource != null) {
            ValueMap resourceProperties = ResourceUtil.getValueMap(thumbnailResource);
            Calendar lastModifiedDate = resourceProperties.get("jcr:lastModified", Calendar.class);

            if (lastModifiedDate != null) {
                thumbnailUrl += "?ck=" + (lastModifiedDate.getTimeInMillis() / 1000);
            }
        }
        return thumbnailUrl;
    }


%>
